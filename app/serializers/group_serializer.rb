# frozen_string_literal: true

class GroupSerializer
  include JSONAPI::Serializer

  attributes :name, :group_type, :simplify_debts, :created_at

  attribute :member_count do |group|
    group.members.size
  end

  attribute :members do |group|
    group.members.map(&:summary)
  end

  attribute :created_by do |group|
    group.creator.summary
  end
end
