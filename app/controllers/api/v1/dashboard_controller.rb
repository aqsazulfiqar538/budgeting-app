# frozen_string_literal: true

class Api::V1::DashboardController < ApplicationController
  def index
    expenses = current_user.expenses.active

    render json: {
      total_expenses: expenses.sum(:amount),
      current_month_total: expenses.where(start_date: Date.current.beginning_of_month..Date.current.end_of_month).sum(:amount),
      category_totals: expenses.joins(:category).group("categories.name").sum(:amount),
      recent_expenses: ExpenseSerializer.new(
        expenses.includes(
          :category,
          expense_participants: :user,
          repayments: [ :from_user, :to_user ]
        ).recent.limit(5),
        include: [ :category ]
      ).serializable_hash,
      recent_ledger_activity: recent_ledger_activity,
      ledger_summary: LedgerService.new(current_user).summary
    }
  end

  private

  def recent_ledger_activity
    recent = Repayment.where("from_user_id = :uid OR to_user_id = :uid", uid: current_user.id)
                      .includes(:from_user, :to_user)
                      .joins(:expense)
                      .select("repayments.*, expenses.title AS expense_title")
                      .order(created_at: :desc)
                      .limit(5)

    recent.map do |r|
      {
        id: r.id,
        expense_title: r.expense_title,
        from: r.from_user.summary,
        to: r.to_user.summary,
        amount: r.amount,
        settled: r.settled, # ask from abubakar bhai how to do this! q: will it hit the db?
        created_at: r.created_at
      }
    end
  end
end
