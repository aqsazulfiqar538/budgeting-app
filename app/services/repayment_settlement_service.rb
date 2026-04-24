class RepaymentSettlementService
  def initialize(repayment, current_user)
    @repayment = repayment
    @current_user = current_user
  end

  def call
    ActiveRecord::Base.transaction do
      @repayment.update!(settled: true, settled_at: Time.current)
      create_settlement_expense
    end

    NotificationService.debt_settled(@repayment, @current_user)
    true
  rescue ActiveRecord::RecordInvalid => e
    false
  end

  private

  def create_settlement_expense
    settlement_category = Category.find_by(name: "Settlement", user_id: nil)

    settlement = Expense.create(
      user_id: @repayment.from_user_id,
      category: settlement_category,
      title: "Settlement: #{@repayment.from_user.full_name} → #{@repayment.to_user.full_name}",
      amount: @repayment.amount,
      start_date: Date.current,
      group_id: @repayment.expense.group_id
    )

    settlement.expense_participants.create(user_id: @repayment.from_user_id, paid_share: @repayment.amount, owed_share: @repayment.amount)
    settlement.expense_participants.create(user_id: @repayment.to_user_id, paid_share: 0, owed_share: 0)
  end
end
