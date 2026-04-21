# frozen_string_literal: true

class Api::V1::FriendsController < ApplicationController
  def index
    friendships = Friendship.accepted.involving(current_user)
                            .includes(:friend)
    render_paginated(
      friendships,
      FriendshipSerializer,
      serializer_options: { params: { current_user: current_user } }
    )
  end

  def show
    friendship = Friendship.accepted.involving(current_user).find(params[:id])
    render json: FriendshipSerializer.new(
      friendship, params: { current_user: current_user }
    ).serializable_hash
  end

  # POST /api/v1/friends — send friend request
  def create
    other_user = User.find(params[:friend_id])
    ids = [ current_user.id, other_user.id ].sort

    friendship = Friendship.new(
      user_id: ids[0],
      friend_id: ids[1],
      requested_by_id: current_user.id,
      status: :pending
    )

    if friendship.save
      NotificationService.friend_request_sent(friendship, current_user, other_user)
      render json: FriendshipSerializer.new(
        friendship, params: { current_user: current_user }
      ).serializable_hash, status: :created
    else
      render_error(friendship.errors.full_messages)
    end
  end

  # DELETE /api/v1/friends/:id — remove friendship
  def destroy
    friendship = Friendship.involving(current_user).find(params[:id])
    friendship.destroy
    head :no_content
  end
end
