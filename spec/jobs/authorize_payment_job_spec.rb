require 'rails_helper'

RSpec.describe AuthorizePaymentJob do
  describe "#perform" do
    it "authorizes a pending transaction" do
      transaction = create(:transaction)

      described_class.perform_now(transaction.id)

      expect(transaction.reload.status).to eq("authorized")
    end

    it "declines the transaction if authorization fails" do
      transaction = create(:transaction, :authorized)

      expect { described_class.perform_now(transaction.id) }.to raise_error(PaymentError::InvalidTransition)

      expect(transaction.reload.status).to eq("declined")
    end

  end
end
