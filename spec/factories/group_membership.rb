FactoryBot.define do
  factory :group_membership do
    association :group
    association :user
  end
end
