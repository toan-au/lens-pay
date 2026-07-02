require 'rails_helper'

RSpec.describe Disputes::CreateService do
  describe ".call" do
    it "creates a dispute on a succeeded transaction" do
      successful_payment = create(:transaction, status: :succeeded, amount: 5000)
      dispute_params = {
        reason: "fraudulent",
        amount: 5000,
        currency: 'JPY'
      }
      result = described_class.call(successful_payment, dispute_params)

      expect(result.dispute).to be_a(Dispute)
      expect(result.status).to be(:created)
      expect(Dispute.count).to eq(1)
    end

    it "raises if the transaction hasn't succeeded" do
      pending_payment = create(:transaction, status: :pending, amount: 5000)
      dispute_params = {
        reason: "fraudulent",
        amount: 5000,
        currency: 'JPY'
      }
      expect { described_class.call(pending_payment, dispute_params) }.to raise_error(DisputeError::InvalidPayment)
    end

    it "raises if the amount exceeds the transaction's amount" do
      successful_payment = create(:transaction, status: :succeeded, amount: 5000)
      dispute_params = {
        reason: "fraudulent",
        amount: 50000,
        currency: 'JPY'
      }

      expect { described_class.call(successful_payment, dispute_params) }.to raise_error(DisputeError::ValidationFailed)
    end

    it "raises if the amount is negative" do
      successful_payment = create(:transaction, status: :succeeded, amount: 5000)
      dispute_params = {
        reason: "fraudulent",
        amount: -5000,
        currency: 'JPY'
      }

      expect { described_class.call(successful_payment, dispute_params) }.to raise_error(DisputeError::ValidationFailed)
    end

    it "raises of amount is zero" do
      successful_payment = create(:transaction, status: :succeeded, amount: 5000)
      dispute_params = {
              reason: "fraudulent",
              amount: 0,
              currency: 'JPY'
            }

      expect { described_class.call(successful_payment, dispute_params) }.to raise_error(DisputeError::ValidationFailed)
    end

    it "raises if the currency doesn't match the transaction's currency" do
      successful_payment = create(:transaction, status: :succeeded, amount: 5000, currency: 'JPY')
      dispute_params = {
        reason: 'fraudulent',
        amount: 3000,
        currency: 'AUD'
      }

      expect { described_class.call(successful_payment, dispute_params) }.to raise_error(DisputeError::MismatchedCurrency)
    end

    it "raises if the reason is not a valid reason code" do
      successful_payment = create(:transaction, status: :succeeded, amount: 5000, currency: 'JPY')
      dispute_params = {
        reason: 'invalid_reason',
        amount: 3000,
        currency: 'JPY'
      }

      expect { described_class.call(successful_payment, dispute_params) }.to raise_error(DisputeError::InvalidReason)
    end

    it "enqueues a dispute.opened webhook on success" do
      successful_payment = create(:transaction, :succeeded, amount: 5000)
      dispute_params = {
        reason: "fraudulent",
        amount: 5000,
        currency: "JPY"
      }

      expect {
        described_class.call(successful_payment, dispute_params)
      }.to have_enqueued_job(WebhookDeliveryJob).with(
        successful_payment.merchant_id, "dispute.opened", "Dispute", anything, request_id: nil
      )
    end
  end
end
