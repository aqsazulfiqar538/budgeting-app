# frozen_string_literal: true

class NotificationSerializer
  include JSONAPI::Serializer

  attributes :notification_type, :content, :read_at, :created_at

  attribute (:read) { |notification| notification.read_at.present? }
  attribute (:created_by) { |notification| notification.created_by.summary }
  attribute (:source) { |notification| notification.source ? { type: notification.source_type, id: notification.source_id } : nil }
end
