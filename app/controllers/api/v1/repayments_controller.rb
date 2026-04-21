# frozen_string_literal: true

class Api::V1::RepaymentsController < ApplicationController
  # PATCH /api/v1/repayments/:id/settle
  def settle
    repayment = find_repayment

    if repayment.settled?
      render_error("Already settled")
      return
    end

    repayment.update(settled: true, settled_at: Time.current)
    create_settlement_expense(repayment)
    create_system_comment(repayment)


    NotificationService.debt_settled(repayment, current_user)

    render json: {
      message: "Settled successfully",
      repayment: {
        id: repayment.id,
        amount: repayment.amount,
        from: { id: repayment.from_user.id, full_name: repayment.from_user.full_name },
        to: { id: repayment.to_user.id, full_name: repayment.to_user.full_name },
        settled: true,
        settled_at: repayment.settled_at
      }
    }
  end

  private

  def find_repayment
    Repayment.where("from_user_id = :uid OR to_user_id = :uid", uid: current_user.id)
             .find(params[:id])
  end

  def create_settlement_expense(repayment)
    settlement_category = Category.find_by!(name: "Settlement", user_id: nil)

    settlement = Expense.create(
      user_id: repayment.from_user_id,
      category: settlement_category,
      title: "Settlement: #{repayment.from_user.full_name} → #{repayment.to_user.full_name}",
      amount: repayment.amount,
      start_date: Date.current,
      group_id: repayment.expense.group_id
    )

    # Add both users as participants so it shows in visible_to for both
    settlement.expense_participants.create(user_id: repayment.from_user_id, paid_share: repayment.amount, owed_share: repayment.amount)
    settlement.expense_participants.create(user_id: repayment.to_user_id, paid_share: 0, owed_share: 0)
  end

  def create_system_comment(repayment)
    repayment.expense.comments.create(
      user: current_user,
      content: "#{current_user.full_name} settled Rs. #{repayment.amount}",
      comment_type: :system_comment
    )
  end
end
