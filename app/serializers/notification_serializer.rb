# frozen_string_literal: true

class NotificationSerializer
  include JSONAPI::Serializer

  attributes :notification_type, :content, :read_at, :created_at

  attribute :read do |notification|
    notification.read_at.present?
  end

  attribute :created_by do |notification|
    notification.created_by.summary
  end

  attribute :source do |notification|
    notification.source ? { type: notification.source_type, id: notification.source_id } : nil
  end
end
