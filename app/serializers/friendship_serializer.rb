# frozen_string_literal: true

class FriendshipSerializer
  include JSONAPI::Serializer

  attributes :status, :created_at

  attribute :friend do |friendship, params|
    friendship.other_user(params[:current_user]).summary
  end

  attribute :requested_by_me do |friendship, params|
    friendship.requested_by_id == params[:current_user].id
  end
end
