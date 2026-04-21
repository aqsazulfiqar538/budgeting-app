# frozen_string_literal: true

class FriendshipSerializer
  include JSONAPI::Serializer

  attributes :status, :created_at
  attribute(:friend) { |friendship, params| friendship.other_user(params[:current_user]).summary }
  attribute(:requested_by_me) { |friendship, params| friendship.requested_by_id == params[:current_user].id }
end
