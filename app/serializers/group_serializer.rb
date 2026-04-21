# frozen_string_literal: true

class GroupSerializer
  include JSONAPI::Serializer

  attributes :name, :group_type, :created_at

  attribute(:user_count) { |group| group.users.size }
  attribute(:users) { |group| group.users.map(&:summary) }
  attribute(:created_by) { |group| group.creator.summary }
end
