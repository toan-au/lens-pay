FactoryBot.define do
  factory :refund do
    association :payment, factory: :transaction
    sequence(:idempotency_key) { |n| "refund_test_key_#{n}" }
    amount { 500 }
    status { :pending }

    trait :succeeded do
      status { :succeeded }
    end

    trait :declined do
      status { :declined }
    end
  end
end
