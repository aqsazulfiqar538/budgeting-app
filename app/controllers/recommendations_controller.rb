class RecommendationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_category, only: %i[index new]
  before_action :validate_category, only: %i[index new create]
  before_action :set_recommendation, only: :show

  def index
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

    @recommendation = current_user.recommendations.build(category: @category)
  end

  def create
    @category = recommendation_params[:category].to_s

    @recommendation = current_user.recommendations.build(
      category:     @category,
      prompt_input: recommendation_params[:prompt_input],
      ai_response:  {}
    )

    # Default action (as tthere's no AI yet)
    @recommendation.action = "no_action"

    if @recommendation.save
      respond_to do |format|
        format.turbo_stream
        format.html do
          redirect_to recommendation_path(@recommendation), notice: "Saved!"
        end
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def recommendation_params
    params.require(:recommendation).permit(:category, :prompt_input)
  end

  def set_category
    @category = params[:category].to_s
  end

  def validate_category
    return if Recommendation::CATEGORIES.include?(@category)

    redirect_to dashboard_path,
                alert: @category.present? ? "Invalid category." : "Please choose a category first."
  end
end