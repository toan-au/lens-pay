require "rails_helper"

RSpec.describe Demo::SetupService do
  describe ".call" do
    it "creates a demo merchant" do
      expect { described_class.call(bulk_count: 0) }.to change(Merchant, :count).by(1)
    end

    it "marks the merchant as demo" do
      result = described_class.call(bulk_count: 0)
      expect(result.merchant.is_demo).to be true
    end

    it "sets demo_expires_at to 24 hours from now" do
      result = described_class.call(bulk_count: 0)
      expect(result.merchant.demo_expires_at).to be_within(5.seconds).of(24.hours.from_now)
    end

    it "returns a raw api_key" do
      result = described_class.call(bulk_count: 0)
      expect(result.api_key).to be_present
    end

    it "creates demo customers" do
      result = described_class.call(bulk_count: 0)
      expect(result.merchant.customers.count).to be >= 2
    end

    it "creates demo payments in mixed states" do
      result = described_class.call(bulk_count: 0)
      statuses = result.merchant.transactions.pluck(:status)
      expect(statuses).to include("succeeded", "authorized", "cancelled", "declined")
    end

    it "seeds enough payments to fill several pages" do
      result = described_class.call
      expect(result.merchant.transactions.count).to be >= 60
    end

    it "spreads bulk payments across the past month" do
      result = described_class.call
      days = result.merchant.transactions.pluck(:created_at).map { |t| t.to_date }.uniq
      expect(days.size).to be >= 15
    end

    it "gives every non-pending bulk payment webhook events" do
      result = described_class.call
      # sample to keep the spec fast
      result.merchant.transactions.where.not(status: :pending).limit(10).each do |payment|
        events = result.merchant.webhook_events.where("payload->'data'->>'id' = ?", payment.uid)
        expect(events.count).to be >= 1
      end
    end

    it "creates payments across payment methods" do
      result = described_class.call(bulk_count: 0)
      methods = result.merchant.transactions.pluck(:payment_method)
      expect(methods).to include("card", "konbini", "bank_transfer")
    end

    it "seeds a pending konbini payment awaiting the customer" do
      result = described_class.call(bulk_count: 0)
      konbini = result.merchant.transactions.find_by(payment_method: :konbini, status: :pending)
      expect(konbini).to be_present
    end

    it "seeds a succeeded bank transfer with confirmed and succeeded events" do
      result = described_class.call(bulk_count: 0)
      bank = result.merchant.transactions.find_by(payment_method: :bank_transfer, status: :succeeded)
      event_types = result.merchant.webhook_events
        .where("payload->'data'->>'id' = ?", bank.uid)
        .pluck(:event_type)
      expect(event_types).to include("payment.confirmed", "payment.succeeded")
    end

    it "creates at least one refund" do
      result = described_class.call(bulk_count: 0)
      payment_ids = result.merchant.transactions.pluck(:id)
      expect(Refund.where(transaction_id: payment_ids).count).to be >= 1
    end

    it "creates webhook events for the seeded payments" do
      result = described_class.call(bulk_count: 0)
      expect(result.merchant.webhook_events.count).to be >= 4
    end

    it "seeds webhook events with the correct event types" do
      result = described_class.call(bulk_count: 0)
      event_types = result.merchant.webhook_events.pluck(:event_type)
      expect(event_types).to include("payment.authorized", "payment.captured", "payment.refunded", "payment.cancelled", "payment.failed")
    end

    it "links webhook events to the correct payments via payload" do
      result = described_class.call(bulk_count: 0)
      # pending cash payments legitimately have no events yet
      result.merchant.transactions.where.not(status: :pending).each do |payment|
        events = result.merchant.webhook_events
          .where("payload->'data'->>'id' = ?", payment.uid)
        expect(events.count).to be >= 1,
          "expected payment #{payment.uid} (#{payment.status}) to have at least one webhook event"
      end
    end

    it "seeds authorized + captured events for succeeded payments" do
      result = described_class.call(bulk_count: 0)
      succeeded = result.merchant.transactions.where(status: :succeeded).first
      event_types = result.merchant.webhook_events
        .where("payload->'data'->>'id' = ?", succeeded.uid)
        .pluck(:event_type)
      expect(event_types).to include("payment.authorized", "payment.captured", "payment.refunded")
    end

    it "seeds authorized + cancelled events for the cancelled payment" do
      result = described_class.call(bulk_count: 0)
      cancelled = result.merchant.transactions.find_by(status: :cancelled)
      event_types = result.merchant.webhook_events
        .where("payload->'data'->>'id' = ?", cancelled.uid)
        .pluck(:event_type)
      expect(event_types).to include("payment.authorized", "payment.cancelled")
    end

    it "seeds authorized + failed events for the declined payment" do
      result = described_class.call(bulk_count: 0)
      declined = result.merchant.transactions.find_by(status: :declined)
      event_types = result.merchant.webhook_events
        .where("payload->'data'->>'id' = ?", declined.uid)
        .pluck(:event_type)
      expect(event_types).to include("payment.authorized", "payment.failed")
    end

    it "seeds refund events linked to their parent payment" do
      result = described_class.call(bulk_count: 0)
      succeeded = result.merchant.transactions.where(status: :succeeded).first
      refund_events = result.merchant.webhook_events
        .where(event_type: "payment.refund.created")
        .where("payload->'data'->>'transaction_uid' = ?", succeeded.uid)
      expect(refund_events.count).to be >= 1
    end

    it "creates a unique merchant email each call" do
      result1 = described_class.call(bulk_count: 0)
      result2 = described_class.call(bulk_count: 0)
      expect(result1.merchant.email).not_to eq(result2.merchant.email)
    end
  end
end
