# frozen_string_literal: true

class Group < ApplicationRecord
  belongs_to :creator, class_name: "User", foreign_key: :created_by_id

  has_many :group_memberships, dependent: :destroy
  has_many :members, through: :group_memberships, source: :user
  has_many :expenses, dependent: :nullify

  enum :group_type, { other: 0, home: 1, trip: 2, couple: 3, apartment: 4 }

  validates :name, presence: true

  scope :active, -> { where(deleted_at: nil) }

  def soft_delete!
    update!(deleted_at: Time.current)
  end

  def restore!
    update!(deleted_at: nil)
  end

  def member?(user)
    group_memberships.exists?(user_id: user.id)
  end
end
