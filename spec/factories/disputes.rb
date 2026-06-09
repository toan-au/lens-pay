FactoryBot.define do
  factory :dispute do
    association :payment, factory: :transaction
    merchant { payment.merchant }
    amount { 500 }
    currency { 'JPY' }
    reason { 'fraudulent' }
    status { :open }
    respond_by { 7.days.from_now }

    trait :merchant_responded do
      status { :merchant_responded }
    end

    trait :won do
      status { :won }
    end

    trait :lost do
      status { :lost }
    end
  end
end
