require 'rails_helper'

RSpec.describe Payments::CaptureService do
  describe ".call" do
    context "full capture" do
      it "transitions an authorized transaction to processing and sets captured_amount to the full amount" do
        transaction = create(:transaction, :authorized, amount: 1000)

        result = described_class.call(transaction)

        expect(result.transaction.status).to eq("processing")
        expect(result.transaction.captured_amount).to eq(1000)
        expect(result.status).to eq(:ok)
      end
    end

    context "partial capture" do
      it "captures a smaller amount than the authorized amount" do
        transaction = create(:transaction, :authorized, amount: 1000)

        result = described_class.call(transaction, captured_amount: 750)

        expect(result.transaction.status).to eq("processing")
        expect(result.transaction.captured_amount).to eq(750)
      end

      it "raises CapturedAmountExceedsAuthorized when captured_amount exceeds the authorized amount" do
        transaction = create(:transaction, :authorized, amount: 1000)

        expect {
          described_class.call(transaction, captured_amount: 1500)
        }.to raise_error(PaymentError::CapturedAmountExceedsAuthorized)
      end

      it "raises ValidationFailed when captured_amount is zero or negative" do
        transaction = create(:transaction, :authorized, amount: 1000)

        expect {
          described_class.call(transaction, captured_amount: 0)
        }.to raise_error(PaymentError::ValidationFailed)
      end
    end

    it "acquires a lock on the transaction before capturing" do
      transaction = create(:transaction, :authorized, amount: 1000)
      expect(transaction).to receive(:with_lock).and_call_original

      described_class.call(transaction)
    end

    it "raises InvalidTransition when the transaction is not authorized" do
      transaction = create(:transaction)

      expect { described_class.call(transaction) }.to raise_error(PaymentError::InvalidTransition)
    end

    it "raises InvalidTransition for a terminal transaction" do
      transaction = create(:transaction, :succeeded)

      expect { described_class.call(transaction) }.to raise_error(PaymentError::InvalidTransition)
    end
  end
end
