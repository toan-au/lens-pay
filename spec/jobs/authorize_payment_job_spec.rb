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

    context "when a request_id is provided" do
      it "restores Current.request_id during execution" do
        transaction = create(:transaction)
        allow(Payments::AuthorizeService).to receive(:call) do
          expect(Current.request_id).to eq("trace-xyz")
        end

        described_class.perform_now(transaction.id, request_id: "trace-xyz")
      end

      it "resets Current.request_id after job completes" do
        transaction = create(:transaction)

        described_class.perform_now(transaction.id, request_id: "trace-xyz")

        expect(Current.request_id).to be_nil
      end

      it "resets Current.request_id even when job raises" do
        transaction = create(:transaction, :authorized)

        expect { described_class.perform_now(transaction.id, request_id: "trace-xyz") }
          .to raise_error(PaymentError::InvalidTransition)

        expect(Current.request_id).to be_nil
      end
    end
  end
end
