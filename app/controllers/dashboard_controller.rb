class DashboardController < ApplicationController
  before_action :authenticate_user!

  def index
    @user = current_user
    @total_expenses = current_user.expenses.sum(:amount)
    @current_month_total = current_user.expenses.current_month.sum(:amount)
    @category_totals = current_user.expenses.joins(:category).group("categories.name").sum(:amount)
    @recent_expenses = current_user.expenses.includes(:category).recent.limit(5)
  end
end
