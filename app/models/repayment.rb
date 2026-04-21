# frozen_string_literal: true

class Repayment < ApplicationRecord
  belongs_to :expense
  belongs_to :from_user, class_name: "User"
  belongs_to :to_user, class_name: "User"

  validates :amount, presence: true, numericality: { greater_than: 0 }

  scope :settled, -> { where(settled: true) }
end
