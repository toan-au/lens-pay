require 'rails_helper'

RSpec.describe Payments::ExpireService do
  describe ".call" do
    it "transitions a pending transaction to expired" do
      transaction = create(:transaction)

      result = described_class.call(transaction)

      expect(result.transaction.status).to eq("expired")
      expect(result.status).to eq(:ok)
    end

    it "enqueues a payment.expired webhook on success" do
      transaction = create(:transaction)

      expect {
        described_class.call(transaction)
      }.to have_enqueued_job(WebhookDeliveryJob).with(
        transaction.merchant_id, "payment.expired", "Transaction", transaction.id, request_id: nil
      )
    end

    it "raises InvalidTransition when the transaction is authorized" do
      transaction = create(:transaction, :authorized)

      expect { described_class.call(transaction) }.to raise_error(PaymentError::InvalidTransition)
    end

    it "raises InvalidTransition when the transaction is succeeded" do
      transaction = create(:transaction, :succeeded)

      expect { described_class.call(transaction) }.to raise_error(PaymentError::InvalidTransition)
    end
  end
end
