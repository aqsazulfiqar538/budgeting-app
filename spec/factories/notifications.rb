# spec/factories/notifications.rb
FactoryBot.define do
  factory :notification do
    association :user
    association :created_by, factory: :user
    notification_type { :expense_added }
    sequence(:content) { |n| "Notification content #{n}" }
    read_at { nil }
    source { nil }
  end
end
