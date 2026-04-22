FactoryBot.define do
  factory :repayment do
    association :expense
    association :from_user, factory: :user
    association :to_user, factory: :user
    amount      { 50.00 }
    settled     { false }
    settled_at  { nil }

    trait :settled do
      settled    { true }
      settled_at { Time.current }
    end
  end
end
