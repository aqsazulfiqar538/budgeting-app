# frozen_string_literal: true

class DashboardService
  def initialize(user)
    @user = user
    @expenses = user.expenses
  end

  def summary
    {
      total_expenses: total_expenses,
      current_month_total: current_month_total,
      category_totals: category_totals,
      recent_expenses: recent_expenses,
      recent_ledger_activity: recent_ledger_activity,
      ledger_summary: LedgerService.new(@user).summary
    }
  end

  private

  def total_expenses
    @expenses.sum(:amount)
  end

  def current_month_total
    @expenses.where(start_date: Date.current.beginning_of_month..Date.current.end_of_month)
             .sum(:amount)
  end

  def category_totals
    @expenses.joins(:category).group("categories.name").sum(:amount)
  end

  def recent_expenses
    ExpenseSerializer.new(
      @expenses.includes(
        :category,
        expense_participants: :user,
        repayments: [ :from_user, :to_user ]
      ).recent.limit(5),
      include: [ :category ]
    ).serializable_hash
  end

  def recent_ledger_activity
    Repayment.where("from_user_id = :uid OR to_user_id = :uid", uid: @user.id)
             .includes(:from_user, :to_user, :expense)
             .order(created_at: :desc)
             .limit(5)
             .map do |r|
               {
                 id: r.id,
                 expense_title: r.expense.title,
                 from: r.from_user.summary,
                 to: r.to_user.summary,
                 amount: r.amount,
                 settled: r.settled,
                 created_at: r.created_at
               }
             end
  end
end
