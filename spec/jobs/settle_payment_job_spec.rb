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

    context "when a request_id is provided" do
      it "restores Current.request_id during execution" do
        transaction = create(:transaction, :processing)
        allow(Payments::CompleteService).to receive(:call) do
          expect(Current.request_id).to eq("trace-xyz")
        end

        described_class.perform_now(transaction.id, request_id: "trace-xyz")
      end

      it "resets Current.request_id after job completes" do
        transaction = create(:transaction, :processing)

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
