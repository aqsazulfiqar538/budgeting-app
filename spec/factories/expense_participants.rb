FactoryBot.define do
  factory :expense_participant do
    association :expense
    association :user
    paid_share  { 0.0 }
    owed_share  { 0.0 }
  end
end
