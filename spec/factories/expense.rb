FactoryBot.define do
  factory :expense do
    association :user
    association :category
    sequence(:title) { |n| "Expense #{n}" }
    amount     { 100.00 }
    start_date { Date.current }
    end_date   { nil }
    notes      { nil }
    deleted_at { nil }
    group      { nil }
  end
end
