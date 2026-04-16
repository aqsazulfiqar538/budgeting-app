class ExpensesController < ApplicationController
  before_action :authenticate_user!

  def index
    expenses = current_user.expenses.filter_by(
      category_id: params[:category_id],
      start_date: params[:start_date],
      end_date: params[:end_date]
    )
    render json: expenses
  end

  def show
    render json: expense
  end

  def create
    new_expense = current_user.expenses.build(expense_params)
    if new_expense.save
      render json: new_expense, status: :created
    else
      render json: { errors: new_expense.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if expense.update(expense_params)
      render json: expense, status: :ok
    else
      render json: { errors: expense.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    expense.destroy
    render json: { message: "Expense deleted successfully." }, status: :ok
  end

  private

  def expense
    @expense ||= current_user.expenses.find(params[:id])
  end

  def expense_params
    params.require(:expense).permit(:title, :amount, :category_id, :start_date, :end_date, :notes)
  end
end
