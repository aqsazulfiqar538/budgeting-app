class Category < ApplicationRecord
  has_many :expenses, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: true
  validates :slug, presence: true, uniqueness: true

  scope :active, ->{ where(active: true) }
  scope :sorted, ->{ order(:sort_order, :name) }
end
