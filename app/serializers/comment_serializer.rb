# frozen_string_literal: true

class CommentSerializer
  include JSONAPI::Serializer

  attributes :content, :comment_type, :created_at

  attribute :user do |comment|
    comment.user.summary
  end
end
