require 'rails_helper'

RSpec.describe Refunds::CreateService do
  describe ".call" do
    it "creates a full refund given valid parameters and a succeeded transaction" do
      transaction = create(:transaction, :succeeded, captured_amount: 1000)
      params = { amount: 1000, idempotency_key: "refund_key_1111" }

      result = described_class.call(transaction, params)

      expect(result.status).to eq(:created)
      expect(Refund.count).to eq(1)
    end

    it "creates a partial refund given valid parameters and a succeeded transaction" do
      transaction = create(:transaction, :succeeded, captured_amount: 1000)
      params = { amount: 400, idempotency_key: "refund_key_1111" }

      result = described_class.call(transaction, params)

      expect(result.status).to eq(:created)
      expect(Refund.count).to eq(1)
    end

    it "raises PaymentNotSucceeded for payments that haven't been succeeded" do
      transaction = create(:transaction, :processing, captured_amount: 1000)
      params = { amount: 400 }

      expect { described_class.call(transaction, params) }.to raise_error(RefundError::PaymentNotSucceeded)
    end

    it "acquires a lock on the transaction before creating a refund" do
      transaction = create(:transaction, :succeeded, captured_amount: 1000)
      params = { amount: 500, idempotency_key: "refund_key_1111" }
      expect(transaction).to receive(:with_lock).and_call_original

      described_class.call(transaction, params)
    end

    it "returns the existing refund when the same idempotency key is used" do
      transaction = create(:transaction, :succeeded, captured_amount: 1000)
      params = { amount: 500, idempotency_key: "refund_key_1111" }
      described_class.call(transaction, params)

      result = described_class.call(transaction, params)

      expect(result.status).to eq(:ok)
      expect(Refund.count).to eq(1)
    end

    it "allows different payments to use the same refund idempotency key" do
      transaction = create(:transaction, :succeeded, captured_amount: 1000)
      other_transaction = create(:transaction, :succeeded, captured_amount: 1000)
      described_class.call(other_transaction, { amount: 500, idempotency_key: "refund_key_1111" })

      result = described_class.call(transaction, { amount: 500, idempotency_key: "refund_key_1111" })

      expect(result.status).to eq(:created)
      expect(Refund.count).to eq(2)
    end

    it "returns the existing refund when the insert loses to a concurrent duplicate" do
      transaction = create(:transaction, :succeeded, captured_amount: 1000)
      existing = create(:refund, payment: transaction, idempotency_key: "refund_key_1111")
      service = described_class.new(transaction, { amount: 500, idempotency_key: "refund_key_1111" })

      # Simulate the race: the pre-insert lookup misses (the winner hasn't
      # committed yet), then the insert hits the unique index.
      allow(service).to receive(:find_existing).and_return(nil, existing)
      allow_any_instance_of(Refund).to receive(:save).and_raise(ActiveRecord::RecordNotUnique)

      result = service.call

      expect(result.status).to eq(:ok)
      expect(result.refund).to eq(existing)
    end

    it "raises PaymentAlreadyRefunded for payments that have already been refunded" do
      transaction = create(:transaction, :succeeded, captured_amount: 500)
      create(:refund, payment: transaction, amount: 500, status: :succeeded)
      params = { amount: 500, idempotency_key: "refund_key_2222" }

      expect { described_class.call(transaction, params) }.to raise_error(RefundError::PaymentAlreadyRefunded)
    end

    it "enqueues a payment.refund.created webhook on success" do
      transaction = create(:transaction, :succeeded, captured_amount: 1000)
      params = { amount: 500, idempotency_key: "refund_key_webhook" }

      expect {
        described_class.call(transaction, params)
      }.to have_enqueued_job(WebhookDeliveryJob).with(
        transaction.merchant_id, "payment.refund.created", "Refund", anything, request_id: nil
      )
    end

    it "raises AmountExceedsRefundable for amounts exceeding the payment's refundable amount" do
      transaction = create(:transaction, :succeeded, captured_amount: 100)
      params = { amount: 10000 }

      expect { described_class.call(transaction, params) }.to raise_error(RefundError::AmountExceedsRefundable)
    end
  end
end
