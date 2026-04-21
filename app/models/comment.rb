# frozen_string_literal: true

class Comment < ApplicationRecord
  belongs_to :expense
  belongs_to :user

  enum :comment_type, { user_comment: 0, system_comment: 1 }

  validates :content, presence: true
end
