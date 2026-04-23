# frozen_string_literal: true

class Api::V1::FriendshipsController < ApplicationController

  def index
    friendships = Friendship.accepted.involving(current_user).includes(:friend)

    render_paginated(
      friendships,
      FriendshipSerializer,
      serializer_options: { params: { current_user: current_user } }
    )
  end

  def show
    friendship = Friendship.accepted.involving(current_user).find(params[:id])
    render json: FriendshipSerializer.new(friendship, params: { current_user: current_user }).serializable_hash
  end

  def create
    other_user = User.find(params[:friend_id])
    friendship = Friendship.between(current_user, other_user)
    
    if friendship.save
      NotificationService.friend_request_sent(friendship, current_user, other_user)
      render json: FriendshipSerializer.new(friendship, params: { current_user: current_user }).serializable_hash, status: :created
    else
      render_error(friendship.errors.full_messages)
    end
  end

  def destroy
    friendship = Friendship.involving(current_user).find(params[:id])
    friendship.destroy
    head :no_content
  end

  def requests
    new_requests = Friendship.pending_for(current_user).includes(:user, :friend)
    render_paginated(
      new_requests,
      FriendshipSerializer,
      serializer_options: { params: { current_user: current_user }}
    )
  end

  def accept
    request = find_incoming_request
    return unless request
    if request.accepted!
      NotificationService.friend_request_accepted(request, current_user, request.requester)
      render json: FriendshipSerializer.new(request, params: { current_user: current_user }).serializable_hash
    else
      render_error(request.errors.full_messages)
    end
  end

  def reject
    request = find_incoming_request
    return unless request

    request.rejected! ? head(:no_content) : render_error(request.errors.full_messages)
  end

  private

  def find_incoming_request
    friendship = Friendship.pending.involving(current_user).find(params[:id])

    if friendship.requested_by_id == current_user.id
      render_error("Cannot accept or reject your own request", status: :forbidden)
      return nil
    end

    friendship
  end
end
