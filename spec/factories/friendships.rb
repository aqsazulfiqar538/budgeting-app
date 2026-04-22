FactoryBot.define do
  factory :friendship do
    association :user
    association :friend, factory: :user
    association :requester, factory: :user

    status { :pending }

    trait :accepted do
      status { :accepted }
    end

    trait :rejected do
      status { :rejected }
    end
  end
end