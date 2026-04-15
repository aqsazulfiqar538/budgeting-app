class ExpensesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_expense, only: [ :show, :edit, :update, :destroy ]
  before_action :load_categories, only: [ :new, :edit, :create, :update ]

  def index
    @expenses = current_user.expenses.filter_by(category_id: params[:category_id],
                                                start_date: params[:start_date],
                                                end_date: params[:end_date])

    @categories = Category.active.sorted
  end

  def show
  end

  def new
    @expense = current_user.expenses.build(start_date: Date.current)
  end

  def create
    @expense = current_user.expenses.build(expense_params)

    if @expense.save
      redirect_to expense_path(@expense), notice: "Expense created successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @expense.update(expense_params)
      redirect_to expense_path(@expense), notice: "Expense updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @expense.destroy
    redirect_to expenses_path, notice: "Expense deleted."
  end

  private

  def set_expense
    @expense = current_user.expenses.find(params[:id])
  end

  def load_categories
    @categories = Category.active.sorted
  end

  def expense_params
    params.require(:expense).permit(:title, :amount, :category_id, :start_date, :end_date, :notes)
  end
end
