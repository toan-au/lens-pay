FactoryBot.define do
  factory :merchant do
    name { "Test Merchant" }
    sequence(:email) { |n| "merchant#{n}@example.com" }
    country { "JP" }
    currency { "JPY" }
  end
end
