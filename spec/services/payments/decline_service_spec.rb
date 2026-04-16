require 'rails_helper'

RSpec.describe Payments::DeclineService do
  describe ".call" do
    %i[pending authorized processing].each do |state|
      it "transitions a #{state} transaction to declined" do
        transaction = create(:transaction, state)

        result = described_class.call(transaction)

        expect(result.transaction.status).to eq("declined")
        expect(result.status).to eq(:ok)
      end
    end

    it "raises InvalidTransition for a succeeded transaction" do
      transaction = create(:transaction, :succeeded)

      expect { described_class.call(transaction) }.to raise_error(PaymentError::InvalidTransition)
    end

    it "raises InvalidTransition for an already declined transaction" do
      transaction = create(:transaction, :declined)

      expect { described_class.call(transaction) }.to raise_error(PaymentError::InvalidTransition)
    end
  end
end
