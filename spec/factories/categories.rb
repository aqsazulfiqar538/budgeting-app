FactoryBot.define do
  factory :category do
    sequence(:name) { |n| "Category #{n}" }
    user            { nil }    # system category by default
    parent          { nil }

    trait :custom do
      association :user
    end

    trait :with_parent do
      association :parent, factory: :category
    end
  end
end
