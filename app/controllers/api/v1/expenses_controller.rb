# frozen_string_literal: true

class Api::V1::ExpensesController < ApplicationController
  before_action :authorize_payer!, only: [ :update, :destroy ]

  def index
    render_paginated(ExpenseQuery.new(current_user, filter_params).call,
                     ExpenseSerializer, includes: [ :category ])
  end

  def show
    render json: ExpenseSerializer.new(expense, include: [ :category ]).serializable_hash
  end

  def create
    resolved_group_id = ResolveOrCreateGroupService.new(
      user:            current_user,
      group_id:        params.dig(:expense, :group_id),
      group_params:    params.dig(:expense, :new_group)&.to_unsafe_h,
      participant_ids: params.dig(:expense, :participants)&.map { |p| p[:user_id].to_i } || []
    ).call

    service = ExpenseCreationService.new(
      user: current_user,
      expense_params: expense_params,
      split_equally: params.dig(:expense, :split_equally),
      participants: params.dig(:expense, :participants)&.map(&:to_unsafe_h),
      group_id: resolved_group_id
    )

    result = service.call
    if result
      render json: ExpenseSerializer.new(result, include: [ :category ]).serializable_hash, status: :created
    else
      render_error(service.errors)
    end
  end

  def update
    if expense.update(expense_params)
      NotificationService.expense_updated(expense, current_user) if expense.shared?
      render json: ExpenseSerializer.new(expense, include: [ :category ]).serializable_hash
    else
      render_error(expense.errors.full_messages)
    end
  end

  def destroy
    NotificationService.expense_deleted(expense, current_user) if expense.shared?
    expense.destroy
    head :no_content
  end

  private

  def expense
    @expense ||= Expense.includes(:category, expense_participants: :user, repayments: [ :from_user, :to_user ])
                        .find(params[:id])
  end

  def authorize_payer!
    render_error("Only the payer can perform this action", status: :forbidden) if expense.user_id != current_user.id
  end

  def expense_params
    params.require(:expense).permit(:title, :amount, :category_id, :start_date, :end_date, :notes )
  end

  def filter_params
    params.permit(:category_id, :start_date, :end_date)
  end
end
