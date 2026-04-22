FactoryBot.define do
  factory :user do
    first_name    { "John" }
    last_name     { "Doe" }
    sequence(:email) { |n| "user#{n}@example.com" }
    password      { "password123" }
    phone_number  { "+923456789072" }
    date_of_birth { "1990-01-01" }
    confirmed_at  { Time.current }  # because of Devise confirmable
  end
end
