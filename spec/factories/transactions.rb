FactoryBot.define do
  factory :transaction do
    amount { 1000 }
    currency { "JPY" }
    sequence(:idempotency_key) { |n| "test_key_#{n}" }
    association :merchant

    trait :authorized do
      status { :authorized }
    end

    trait :processing do
      status { :processing }
    end

    trait :succeeded do
      status { :succeeded }
      captured_amount { 1000 }
    end

    trait :declined do
      status { :declined }
    end
  end
end
