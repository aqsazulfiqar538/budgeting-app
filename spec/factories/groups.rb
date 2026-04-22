FactoryBot.define do
  factory :group do
    association :creator, factory: :user

    sequence(:name) { |n| "Group #{n}" }
    group_type { :other }

    deleted_at { nil }
  end
end
