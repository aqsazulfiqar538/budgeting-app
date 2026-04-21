# frozen_string_literal: true

class Friendship < ApplicationRecord
  belongs_to :user
  belongs_to :friend, class_name: "User"
  belongs_to :requester, class_name: "User", foreign_key: :requested_by_id

  enum :status, { pending: 0, accepted: 1, rejected: 2 }

  validates :user_id, uniqueness: { scope: :friend_id, message: "friendship already exists" }
  validate :canonical_ordering
  validate :not_self_friendship

  scope :involving, ->(user) { where(user_id: user.id).or(where(friend_id: user.id)) }
  scope :accepted, -> { where(status: :accepted) }

  # Pending requests where the given user is the recipient (not the requester)
  scope :pending_for, ->(user) {
    pending.involving(user).where.not(requested_by_id: user.id)
  }

  # Returns the "other" user in the friendship relative to the given user
  def other_user(current)
    current.id == user_id ? friend : user
  end

  private

  def canonical_ordering
    if user_id.present? && friend_id.present? && user_id >= friend_id
      errors.add(:base, "Invalid friendship: IDs must be canonically ordered")
    end
  end

  def not_self_friendship
    if user_id.present? && user_id == friend_id
      errors.add(:base, "Cannot befriend yourself")
    end
  end
end
