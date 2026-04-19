# frozen_string_literal: true

class ExpenseParticipantSerializer
  include JSONAPI::Serializer

  attributes :paid_share, :owed_share

  attribute :net_balance, &:net_balance

  attribute :user do |participant|
    participant.user.summary
  end
end
