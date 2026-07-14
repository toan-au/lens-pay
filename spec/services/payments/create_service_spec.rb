require "rails_helper"

RSpec.describe Payments::CreateService do
  describe "concurrent create race" do
    it "returns the existing payment when the insert loses to a concurrent duplicate" do
      merchant = create(:merchant)
      existing = create(:transaction, merchant: merchant, idempotency_key: "order-1")
      service = described_class.new(merchant, { amount: 1000, currency: "JPY", idempotency_key: "order-1" })

      # Simulate the race: the pre-insert lookup misses (the winner hasn't
      # committed yet), then the insert hits the unique index.
      allow(service).to receive(:find_existing).and_return(nil, existing)
      allow_any_instance_of(Transaction).to receive(:save).and_raise(ActiveRecord::RecordNotUnique)

      result = service.call

      expect(result.status).to eq(:ok)
      expect(result.transaction).to eq(existing)
    end
  end
end
