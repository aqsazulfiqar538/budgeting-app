# frozen_string_literal: true

class Api::V1::NotificationsController < ApplicationController
  # GET /api/v1/notifications
  def index
    notifications = current_user.notifications.recent.includes(:created_by)
    pagy, records = pagy(notifications)
    render json: {
      **NotificationSerializer.new(records).serializable_hash,
      meta: pagy_metadata(pagy).merge(unread_count: current_user.notifications.unread.count)
    }
  end

  # PATCH /api/v1/notifications/mark_read
  def mark_read
    current_user.notifications.unread.update_all(read_at: Time.current)
    render_success(message: "All notifications marked as read")
  end
end
