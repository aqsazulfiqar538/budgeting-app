FactoryBot.define do
  factory :category do
    sequence(:name) { |n| "Category #{n}" }
    user            { nil }    # system category
    parent          { nil }

    trait :custom do
      association :user
    end
  end
end
