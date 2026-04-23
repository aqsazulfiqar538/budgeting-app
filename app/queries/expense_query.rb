# frozen_string_literal: true

class ExpenseQuery
  def initialize(user, filters = {})
    @user    = user
    @filters = filters
  end

  def call
    scope = base_scope
    scope = scope.where(category_id: filters[:category_id]) if filters[:category_id].present?
    scope.recent
  end

  private

  attr_reader :user, :filters

  def base_scope
    Expense.visible_to(user)
           .includes(:category, expense_participants: :user, repayments: [:from_user, :to_user])
           .where.not(id: ExpenseParticipant.select(:expense_id).group(:expense_id).having("COUNT(*) > 1"))
  end
end
