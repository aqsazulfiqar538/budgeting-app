# frozen_string_literal: true

class Comment < ApplicationRecord
  belongs_to :expense
  belongs_to :user

  enum :comment_type, { user_comment: 0, system_comment: 1 }

  validates :content, presence: true

  scope :active, -> { where(deleted_at: nil) }
  scope :order_by, -> { order(:created_at) }

  def soft_delete!
    update!(deleted_at: Time.current)
  end
end
