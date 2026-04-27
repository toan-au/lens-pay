require 'rails_helper'

RSpec.describe Payments::CompleteService do
  describe ".call" do
    it "transitions a processing transaction to succeeded" do
      transaction = create(:transaction, :processing)

      result = described_class.call(transaction)

      expect(result.transaction.status).to eq("succeeded")
      expect(result.status).to eq(:ok)
    end

    it "persists the status change" do
      transaction = create(:transaction, :processing)

      described_class.call(transaction)

      expect(transaction.reload.status).to eq("succeeded")
    end

    it "raises InvalidTransition when the transaction is not processing" do
      transaction = create(:transaction, :authorized)

      expect { described_class.call(transaction) }.to raise_error(PaymentError::InvalidTransition)
    end

    it "raises InvalidTransition for a terminal transaction" do
      transaction = create(:transaction, :declined)

      expect { described_class.call(transaction) }.to raise_error(PaymentError::InvalidTransition)
    end

    it "enqueues a webhook delivery job on success" do
      transaction = create(:transaction, :processing)

      expect {
        described_class.call(transaction)
      }.to have_enqueued_job(WebhookDeliveryJob).with(
        transaction.merchant_id, "payment.succeeded", "Transaction", transaction.id
      )
    end

    it "does not enqueue a webhook delivery job when the transition fails" do
      transaction = create(:transaction, :authorized)
      described_class.call(transaction) rescue PaymentError::InvalidTransition

      expect(WebhookDeliveryJob).not_to have_been_enqueued
    end
  end
end
