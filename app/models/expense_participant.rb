# frozen_string_literal: true

class ExpenseParticipant < ApplicationRecord
  belongs_to :expense
  belongs_to :user

  validates :paid_share, numericality: { greater_than_or_equal_to: 0 }
  validates :owed_share, numericality: { greater_than_or_equal_to: 0 }
  validates :user_id, uniqueness: { scope: :expense_id, message: "is already a participant" }

  def net_balance
    owed_share - paid_share
  end
end
