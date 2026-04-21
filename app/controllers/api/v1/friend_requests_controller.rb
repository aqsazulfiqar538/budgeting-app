# frozen_string_literal: true

class Api::V1::FriendRequestsController < ApplicationController
  def index
    requests = Friendship.pending_for(current_user)
                         .includes(:user, :friend)
    render_paginated(
      requests,
      FriendshipSerializer,
      serializer_options: { params: { current_user: current_user } }
    )
  end

  # PATCH /api/v1/friends/requests/:id/accept
  def accept
    request = find_incoming_request
    return unless request

    begin
      request.accepted!
      NotificationService.friend_request_accepted(request, current_user, request.requester)
      render json: FriendshipSerializer.new(
        request, params: { current_user: current_user }
      ).serializable_hash
    rescue ActiveRecord::RecordInvalid => e
      render_error(e.record.errors.full_messages)
    rescue StandardError
      render_error("Unable to accept friend request", status: :internal_server_error)
    end
  end

  # PATCH /api/v1/friends/requests/:id/reject
  def reject
    request = find_incoming_request
    return unless request

    begin
      request.rejected!
      head :no_content
    rescue ActiveRecord::RecordInvalid => e
      render_error(e.record.errors.full_messages)
    rescue StandardError
      render_error("Unable to reject friend request", status: :internal_server_error)
    end
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
