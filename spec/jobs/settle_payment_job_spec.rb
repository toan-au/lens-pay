require 'rails_helper'

RSpec.describe SettlePaymentJob, type: :job do
  describe "#perform" do
    it "marks a transaction as succeeded" do
      transaction = create(:transaction, :processing)

      described_class.perform_now(transaction.id)
      expect(transaction.reload.status).to eq("succeeded")
    end
    it "declines the transaction and re-raises the error if settlement fails" do
      transaction = create(:transaction, :authorized)

      expect { described_class.perform_now(transaction.id) }
        .to raise_error(PaymentError::InvalidTransition)

      expect(transaction.reload.status).to eq("declined")
    end
  end
end
