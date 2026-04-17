FactoryBot.define do
  factory :refund do
    payment { nil }
    amount { 1 }
    status { 1 }
    uid { "MyString" }
  end
end
