require 'rails_helper'

RSpec.describe Payments::CancelService do
  describe ".call" do
    it "transitions a pending transaction to cancelled" do
      transaction = create(:transaction)

      result = described_class.call(transaction)

      expect(result.transaction.status).to eq("cancelled")
      expect(result.status).to eq(:ok)
    end

    it "transitions an authorized transaction to cancelled" do
      transaction = create(:transaction, :authorized)

      result = described_class.call(transaction)

      expect(result.transaction.status).to eq("cancelled")
    end

    it "enqueues a payment.cancelled webhook on success" do
      transaction = create(:transaction, :authorized)

      expect {
        described_class.call(transaction)
      }.to have_enqueued_job(WebhookDeliveryJob).with(
        transaction.merchant_id, "payment.cancelled", "Transaction", transaction.id, request_id: nil
      )
    end

    it "raises InvalidTransition when the transaction is processing" do
      transaction = create(:transaction, :processing)

      expect { described_class.call(transaction) }.to raise_error(PaymentError::InvalidTransition)
    end

    it "raises InvalidTransition when the transaction is succeeded" do
      transaction = create(:transaction, :succeeded)

      expect { described_class.call(transaction) }.to raise_error(PaymentError::InvalidTransition)
    end
  end
end
