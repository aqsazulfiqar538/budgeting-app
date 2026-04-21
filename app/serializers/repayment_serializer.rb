# frozen_string_literal: true

class RepaymentSerializer
  include JSONAPI::Serializer

  attributes :amount, :settled, :settled_at
  attribute (:from_user) { |repayment| repayment.from_user.summary }
  attribute (:to_user) { |repayment| repayment.to_user.summary }
end
