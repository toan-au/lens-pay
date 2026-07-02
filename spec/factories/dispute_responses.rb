FactoryBot.define do
  factory :dispute_response do
    association :dispute
    evidence { { customer_comment: "confirmation" } }
  end
end
