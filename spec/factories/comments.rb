FactoryBot.define do
  factory :comment do
    association :expense
    association :user
    sequence(:content) { |n| "Comment #{n}" }
    comment_type { :user_comment }
    deleted_at   { nil }

    trait :system do
      comment_type { :system_comment }
    end

    trait :deleted do
      deleted_at { Time.current }
    end
  end
end
