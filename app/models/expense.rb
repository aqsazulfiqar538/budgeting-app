# == Schema Information
#
# Table name: expenses
#
#  id          :integer          not null, primary key
#  user_id     :integer          not null
#  category_id :integer          not null
#  title       :string           not null
#  amount      :decimal(12, 2)   not null
#  start_date  :date             not null
#  end_date    :date
#  notes       :text
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  group_id    :integer
#  deleted_at  :datetime
#
# Indexes
#
#  index_expenses_on_category_id              (category_id)
#  index_expenses_on_deleted_at               (deleted_at)
#  index_expenses_on_group_id                 (group_id)
#  index_expenses_on_user_id                  (user_id)
#  index_expenses_on_user_id_and_category_id  (user_id,category_id)
#  index_expenses_on_user_id_and_start_date   (user_id,start_date)
#

# frozen_string_literal: true

class Expense < ApplicationRecord
  belongs_to :user
  belongs_to :category
  belongs_to :group, optional: true

  has_many :expense_participants, dependent: :destroy
  has_many :participants, through: :expense_participants, source: :user
  has_many :repayments, dependent: :destroy
  has_many :comments, dependent: :destroy

  validates :title, presence: true
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :start_date, presence: true
  validate :category_accessible_to_user, if: :category_id?

  scope :recent, -> { order(start_date: :desc, created_at: :desc) }

  #expenses where user is the payer or a participant
  scope :visible_to, ->(user) {
      left_joins(:expense_participants)
      .where("expenses.user_id = :uid OR expense_participants.user_id = :uid", uid: user.id).distinct
  }

  def shared?
    expense_participants.size > 1
  end

  private

  def category_accessible_to_user
    return unless category
    unless category.user_id.nil? || category.user_id == user_id
      errors.add(:category, "is not accessible")
    end
  end
end
