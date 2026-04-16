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
#
# Indexes
#
#  index_expenses_on_category_id              (category_id)
#  index_expenses_on_user_id                  (user_id)
#  index_expenses_on_user_id_and_category_id  (user_id,category_id)
#  index_expenses_on_user_id_and_start_date   (user_id,start_date)
#

class Expense < ApplicationRecord
  belongs_to :user
  belongs_to :category

  validates :title, presence: true
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :start_date, presence: true
  validate :end_date_after_start_date, if: -> { start_date.present? && end_date.present? }

  scope :recent, -> { order(start_date: :desc, created_at: :desc) }
  scope :by_category, ->(category_id) { where(category_id: category_id) if category_id.present? }
  scope :in_date_range, ->(from, to){
    scope = all
    scope = scope.where("start_date >= ?", from) if from.present?
    scope = scope.where("start_date <= ?", to) if to.present?
    scope
  }
  scope :current_month, -> {
    where(start_date: Date.current.beginning_of_month..Date.current.end_of_month)
  }
  scope :filter_by, ->(category_id: nil, start_date: nil, end_date: nil) {
    includes(:category)
      .by_category(category_id)
      .in_date_range(start_date ,end_date)
      .recent
  }

  private

  def end_date_after_start_date
    errors.add(:end_date, "must be on or after start date") if end_date < start_date
  end
end
