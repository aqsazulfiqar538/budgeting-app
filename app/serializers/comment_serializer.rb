# frozen_string_literal: true

class CommentSerializer
  include JSONAPI::Serializer

  attributes :content, :comment_type, :created_at

  attribute(:user) { |comment| comment.user.summary } #If i only return user_id, frontend must call /users/:id for every unique commenter. Slower and more complex.
end
