class Api::V1::DashboardController < ApplicationController
  def index
    total_expenses = current_user.expenses.sum(:amount)
    current_month_total = current_user.expenses.current_month.sum(:amount)
    category_totals = current_user.expenses.joins(:category).group("categories.name").sum(:amount)
    recent_expenses = current_user.expenses.includes(:category).recent.limit(5)

    render json: {
      total_expenses: total_expenses,
      current_month_total: current_month_total,
      category_totals: category_totals,
      recent_expenses: ExpenseSerializer.new(recent_expenses, include: [:category]).serializable_hash
    }
  end
end
