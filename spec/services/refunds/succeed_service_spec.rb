require 'rails_helper'

RSpec.describe Refunds::SucceedService do
  describe ".call" do
    it "transitions a pending refund to succeeded" do
      refund = create(:refund, status: :pending)

      result = described_class.call(refund)

      expect(result.status).to eq(:ok)
      expect(refund.reload.status).to eq("succeeded")
    end

    it "raises InvalidTransition when refund is not pending" do
      refund = create(:refund, status: :declined)

      expect { described_class.call(refund) }.to raise_error(RefundError::InvalidTransition)
    end

    it "enqueues a webhook delivery job on success" do
      refund = create(:refund, status: :pending)

      expect {
        described_class.call(refund)
      }.to have_enqueued_job(WebhookDeliveryJob).with(
        refund.payment.merchant_id, "refund.succeeded", "Refund", refund.id
      )
    end

    it "does not enqueue a webhook delivery job when the transition fails" do
      refund = create(:refund, status: :declined)
      described_class.call(refund) rescue RefundError::InvalidTransition

      expect(WebhookDeliveryJob).not_to have_been_enqueued
    end
  end
end
