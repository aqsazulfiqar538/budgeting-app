# frozen_string_literal: true

class RepaymentSerializer
  include JSONAPI::Serializer

  attributes :amount, :settled, :settled_at

  attribute :from_user do |repayment|
    repayment.from_user.summary
  end

  attribute :to_user do |repayment|
    repayment.to_user.summary
  end
end
