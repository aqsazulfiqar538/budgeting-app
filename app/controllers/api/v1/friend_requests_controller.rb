# frozen_string_literal: true

class Api::V1::FriendRequestsController < ApplicationController
  include FriendshipRenderable

  # GET /api/v1/friends/requests — pending incoming requests
  def index
    requests = Friendship.pending_for(current_user)
                         .includes(:user, :friend)
    render_paginated_friendships(requests)
  end

  # PATCH /api/v1/friends/requests/:id/accept
  def accept
    request = find_incoming_request
    return unless request

    request.accepted!
    NotificationService.friend_request_accepted(request, current_user, request.requester)
    render json: FriendshipSerializer.new(
      request, params: { current_user: current_user }
    ).serializable_hash
  end

  # PATCH /api/v1/friends/requests/:id/reject
  def reject
    request = find_incoming_request
    return unless request

    request.rejected!
    head :no_content
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
