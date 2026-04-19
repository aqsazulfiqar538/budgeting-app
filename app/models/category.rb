class Category < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :parent, class_name: "Category", optional: true
  has_many :subcategories, class_name: "Category", foreign_key: :parent_id, dependent: :destroy
  has_many :expenses, dependent: :restrict_with_error

  validates :name, presence: true
  validate :parent_must_be_system_or_own, if: :parent_id?

  scope :system_categories, -> { where(user_id: nil) }
  scope :active, -> { where(active: true) }

  private

  def parent_must_be_system_or_own
    if parent.user_id.present? && parent.user_id != user_id
      errors.add(:parent_id, "must be a system category or your own category")
    end
  end
end
