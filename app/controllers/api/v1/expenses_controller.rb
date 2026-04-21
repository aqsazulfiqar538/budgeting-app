# frozen_string_literal: true

class Api::V1::ExpensesController < ApplicationController
  before_action :authorize_payer!, only: [ :update, :destroy ]

  # GET /api/v1/expenses
  def index
    render_paginated(fetch_filtered_expenses, ExpenseSerializer, includes: [ :category ])
  end

  # GET /api/v1/expenses/:id
  def show
    render json: ExpenseSerializer.new(expense, include: [ :category ]).serializable_hash
  end

  # POST /api/v1/expenses
  def create
    group_id = resolve_group_id

    service = ExpenseCreationService.new(
      user: current_user,
      expense_params: expense_params,
      split_equally: params.dig(:expense, :split_equally),
      participants: params.dig(:expense, :participants)&.map(&:to_unsafe_h),
      group_id: group_id
    )

    result = service.call
    if result
      render json: ExpenseSerializer.new(result, include: [ :category ]).serializable_hash, status: :created
    else
      render_error(service.errors)
    end
  end

  # PATCH /api/v1/expenses/:id
  def update
    if expense.update(expense_params)
      NotificationService.expense_updated(expense, current_user) if expense.shared?
      render json: ExpenseSerializer.new(expense, include: [ :category ]).serializable_hash
    else
      render_error(expense.errors.full_messages)
    end
  end

  # DELETE /api/v1/expenses/:id
  def destroy
    NotificationService.expense_deleted(expense, current_user) if expense.shared?
    expense.update!(deleted_at: Time.current) # soft delete done here
    head :no_content
  end

  private

  def fetch_filtered_expenses
    expenses = Expense.visible_to(current_user) # if removed will show all indivitual expenses from all users
                      .includes(:category)
                      .where.not(id: ExpenseParticipant.select(:expense_id).group(:expense_id).having("COUNT(*) > 1"))

    expenses = expenses.where(category_id: params[:category_id]) if params[:category_id].present?
    expenses = expenses.where("start_date >= ?", params[:start_date]) if params[:start_date].present?
    expenses = expenses.where("start_date <= ?", params[:end_date]) if params[:end_date].present?

    expenses.recent
  end

  def expense
    @expense ||= Expense.includes(:category, expense_participants: :user, repayments: [ :from_user, :to_user ])
                        .find(params[:id])
  end

  def authorize_payer!
    render_error("Only the payer can perform this action", status: :forbidden) unless expense.user_id == current_user.id
  end

  def resolve_group_id
    # Use existing group if provided
    return params.dig(:expense, :group_id) if params.dig(:expense, :group_id).present?

    # Create new group inline if new_group params provided
    new_group_params = params.dig(:expense, :new_group)
    return nil unless new_group_params.present?

    group = current_user.created_groups.create!(
      name: new_group_params[:name],
      group_type: new_group_params[:group_type] || :other
    )
    group.group_memberships.create!(user_id: current_user.id)

    # Add participants as group members (only friends)
    friend_ids = current_user.friends.pluck(:id)
    participant_ids = params.dig(:expense, :participants)&.map { |p| p[:user_id].to_i } || []
    participant_ids.each do |uid|
      next if uid == current_user.id
      next unless friend_ids.include?(uid)
      group.group_memberships.find_or_create_by(user_id: uid)
    end

    group.id
  end

  def expense_params
    params.require(:expense).permit(:title, :amount, :category_id, :start_date, :end_date, :notes)
  end
end
