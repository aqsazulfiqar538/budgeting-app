class RecommendationsController < ApplicationController
  before_action :authenticate_user!

  def index
    @category = params[:category].to_s

    unless Recommendation::CATEGORIES.include?(@category)
      redirect_to dashboard_path, alert: "Invalid category." and return
    end

    @recommendations = current_user.recommendations
                                   .public_send(@category)
                                   .recent
  end

  def show
    @recommendation = current_user.recommendations.find_by!(id: params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to dashboard_path, alert: "Recommendation not found."
  end

  def new
    @category = params[:category].to_s
    unless Recommendation::CATEGORIES.include?(@category)
      redirect_to dashboard_path, alert: "Please choose a category first." and return
    end
    @recommendation = Recommendation.new
  end

  def create
    @category = params[:recommendation][:category].to_s

    unless Recommendation::CATEGORIES.include?(@category)
      redirect_to dashboard_path, alert: "Invalid category." and return
    end

    ai_response = AiBudgetService.new(
      @category,
      params[:recommendation][:prompt_input]
    ).call

    @recommendation = current_user.recommendations.build(
      category:     @category,
      prompt_input: params[:recommendation][:prompt_input],
      ai_response:  ai_response
    )

    @recommendation.action = @recommendation.derive_action

    if @recommendation.save
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to recommendation_path(@recommendation), notice: "Saved!" }
      end
    else
      render :new, status: :unprocessable_entity
    end
  end
end
