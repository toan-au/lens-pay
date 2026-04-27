require 'rails_helper'

RSpec.describe Webhooks::PaymentPayloadService do
  describe ".call" do
    let(:merchant) { create(:merchant) }
    let(:transaction) { create(:transaction, :succeeded, merchant: merchant) }

    subject(:data) { described_class.call(transaction) }

    it "includes the transaction uid" do
      expect(data[:id]).to eq(transaction.uid)
    end

    it "sets resource to payment" do
      expect(data[:resource]).to eq("payment")
    end

    it "includes the current status" do
      expect(data[:status]).to eq("succeeded")
    end

    it "includes the amount and currency" do
      expect(data[:amount]).to eq(transaction.amount)
      expect(data[:currency]).to eq(transaction.currency)
    end

    it "includes the captured_amount" do
      expect(data[:captured_amount]).to eq(transaction.captured_amount)
    end

    it "includes the idempotency_key" do
      expect(data[:idempotency_key]).to eq(transaction.idempotency_key)
    end

    it "includes the merchant_uid" do
      expect(data[:merchant_uid]).to eq(merchant.uid)
    end

    it "includes created_at as an ISO8601 string" do
      expect(data[:created_at]).to eq(transaction.created_at.iso8601)
    end
  end
end
