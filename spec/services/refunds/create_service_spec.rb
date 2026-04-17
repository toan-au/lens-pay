require 'rails_helper'

RSpec.describe Refunds::CreateService do
  describe ".call" do
    it "creates a full refund given valid parameters and a succeeded transaction" do
      transaction = create(:transaction, :succeeded, captured_amount: 1000)
      params = { amount: 1000 }

      result = described_class.call(params, transaction)

      expect(result.status).to eq(:created)
      expect(Refund.count).to eq(1)
    end

    it "creates a partial refund given valid parameters and a succeeded transaction" do
      transaction = create(:transaction, :succeeded, captured_amount: 1000)
      params = { amount: 400 }

      result = described_class.call(params, transaction)

      expect(result.status).to eq(:created)
      expect(Refund.count).to eq(1)
    end

    it "raises PaymentNotSucceeded for payments that haven't been succeeded" do
      transaction = create(:transaction, :processing, captured_amount: 1000)
      params = { amount: 400 }

      expect { described_class.call(params, transaction) }.to raise_error(RefundError::PaymentNotSucceeded)
    end

    it "raises PaymentAlreadyRefunded for payments that have already been refunded" do
      transaction = create(:transaction, :succeeded, captured_amount: 0)
      params = { amount: 500 }

      expect { described_class.call(params, transaction) }.to raise_error(RefundError::PaymentAlreadyRefunded)
    end

    it "raises AmountExceedsRefundable for amounts exceeding the payment's refundable amount" do
      transaction = create(:transaction, :succeeded, captured_amount: 100)
      params = { amount: 10000 }

      expect { described_class.call(params, transaction) }.to raise_error(RefundError::AmountExceedsRefundable)
    end
  end
end
