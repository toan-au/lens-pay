FactoryBot.define do
  factory :transaction do
    amount { 1000 }
    currency { "JPY" }
    payment_method { :card }
    sequence(:idempotency_key) { |n| "test_key_#{n}" }
    association :merchant

    trait :konbini do
      payment_method { :konbini }
    end

    trait :bank_transfer do
      payment_method { :bank_transfer }
    end

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

    trait :cancelled do
      status { :cancelled }
    end

    trait :expired do
      status { :expired }
      expires_at { 1.hour.ago }
    end
  end
end
