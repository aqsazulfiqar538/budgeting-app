class Api::V1::ExpensesController < ApplicationController
  def index
    expenses = current_user.expenses.filter_by(
      category_id: params[:category_id],
      start_date: params[:start_date],
      end_date: params[:end_date]
    )
    render json: ExpenseSerializer.new(expenses, include: [ :category ]).serializable_hash
  end

  def show
    render json: ExpenseSerializer.new(expense, include: [ :category ]).serializable_hash
  end

  def create
    new_expense = current_user.expenses.new(expense_params)
    if new_expense.save
      render json: ExpenseSerializer.new(new_expense, include: [ :category ]).serializable_hash, status: :created
    else
      render json: { errors: new_expense.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if expense.update(expense_params)
      render json: ExpenseSerializer.new(expense, include: [ :category ]).serializable_hash
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
