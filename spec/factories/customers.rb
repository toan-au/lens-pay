FactoryBot.define do
  factory :customer do
    association :merchant
    name { "Jane Doe" }
    email { "jane@example.com" }
    metadata { nil }
    deleted_at { nil }
  end
end
