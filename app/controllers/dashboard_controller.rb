class DashboardController < ApplicationController
  before_action :authenticate_user!

  def index
    @user = current_user

    @category_counts = {
      food:       current_user.recommendations.food.count,
      travel:     current_user.recommendations.travel.count,
      medication: current_user.recommendations.medication.count
    }
  end
end
