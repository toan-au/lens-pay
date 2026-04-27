require 'rails_helper'

RSpec.describe Webhooks::BuildPayloadService do
  describe ".call" do
    let(:event_id) { "evt_abc123" }

    context "with a transaction" do
      let(:transaction) { create(:transaction, :succeeded) }

      subject(:payload) { JSON.parse(described_class.call(event_type: "payment.succeeded", resource: transaction, event_id: event_id)) }

      it "sets the event id" do
        expect(payload["id"]).to eq(event_id)
      end

      it "sets the event type" do
        expect(payload["type"]).to eq("payment.succeeded")
      end

      it "sets resource to event" do
        expect(payload["resource"]).to eq("event")
      end

      it "includes a created_at timestamp" do
        expect(payload["created_at"]).to be_present
      end

      it "includes payment data in the data field" do
        expect(payload["data"]["resource"]).to eq("payment")
        expect(payload["data"]["id"]).to eq(transaction.uid)
      end
    end

    context "with a refund" do
      let(:transaction) { create(:transaction, :succeeded) }
      let(:refund) { create(:refund, :succeeded, payment: transaction) }

      subject(:payload) { JSON.parse(described_class.call(event_type: "refund.succeeded", resource: refund, event_id: event_id)) }

      it "includes refund data in the data field" do
        expect(payload["data"]["resource"]).to eq("refund")
        expect(payload["data"]["id"]).to eq(refund.uid)
      end
    end
  end
end
