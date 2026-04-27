require 'rails_helper'

RSpec.describe Webhooks::RefundPayloadService do
  describe ".call" do
    let(:transaction) { create(:transaction, :succeeded) }
    let(:refund) { create(:refund, :succeeded, payment: transaction) }

    subject(:data) { described_class.call(refund) }

    it "includes the refund uid" do
      expect(data[:id]).to eq(refund.uid)
    end

    it "sets resource to refund" do
      expect(data[:resource]).to eq("refund")
    end

    it "includes the current status" do
      expect(data[:status]).to eq("succeeded")
    end

    it "includes the amount" do
      expect(data[:amount]).to eq(refund.amount)
    end

    it "derives currency from the parent transaction" do
      expect(data[:currency]).to eq(transaction.currency)
    end

    it "includes the transaction_uid" do
      expect(data[:transaction_uid]).to eq(transaction.uid)
    end

    it "includes created_at as an ISO8601 string" do
      expect(data[:created_at]).to eq(refund.created_at.iso8601)
    end
  end
end
