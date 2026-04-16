FactoryBot.define do
  factory :transaction do
    amount { 1000 }
    currency { "JPY" }
    sequence(:idempotency_key) { |n| "test_key_#{n}" }
    association :merchant
  end
end
