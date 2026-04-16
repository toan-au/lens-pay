require 'rails_helper'

RSpec.describe Payments::AuthorizeService do
  describe ".call" do
    it "transitions a pending transaction to authorized" do
      transaction = create(:transaction)

      result = described_class.call(transaction)

      expect(result.transaction.status).to eq("authorized")
      expect(result.status).to eq(:ok)
    end

    it "persists the status change" do
      transaction = create(:transaction)

      described_class.call(transaction)

      expect(transaction.reload.status).to eq("authorized")
    end

    it "raises InvalidTransition when the transaction is not pending" do
      transaction = create(:transaction, :authorized)

      expect { described_class.call(transaction) }.to raise_error(PaymentError::InvalidTransition)
    end

    it "raises InvalidTransition for a terminal transaction" do
      transaction = create(:transaction, :succeeded)

      expect { described_class.call(transaction) }.to raise_error(PaymentError::InvalidTransition)
    end
  end
end
