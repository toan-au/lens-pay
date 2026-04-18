FactoryBot.define do
  factory :refund do
    association :payment, factory: :transaction
    amount { 500 }
    status { :pending }
  end
end
