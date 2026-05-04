FactoryBot.define do
  factory :webhook_capture do
    association :merchant
    event_type { "payment.succeeded" }
    payload { { "id" => "evt_123", "type" => "payment.succeeded", "data" => {} } }
  end
end
