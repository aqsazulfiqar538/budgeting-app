# frozen_string_literal: true

class ExpenseSerializer
  include JSONAPI::Serializer

  attributes :title, :amount, :category_id, :start_date, :end_date, :notes, :created_at, :updated_at, :group_id

  attribute :shared do |object|
    object.shared?
  end

  belongs_to :category, serializer: CategorySerializer

  attribute :participants do |expense|
    expense.expense_participants.map do |p|
      { user: p.user.summary, paid_share: p.paid_share, owed_share: p.owed_share, net_balance: p.net_balance }
    end
  end

  attribute :repayments do |expense|
    expense.repayments.map do |r|
      { id: r.id, from: r.from_user.summary, to: r.to_user.summary, amount: r.amount, settled: r.settled }
    end
  end
end
