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
  end
end
