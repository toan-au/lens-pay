module Refunds
  class DeclineService < ApplicationService
    Result = Data.define(:refund, :status)

    def initialize(refund)
      @refund = refund
    end

    def perform
      @refund.with_lock do
        @refund.decline!
      end
      WebhookDeliveryJob.perform_later(@refund.payment.merchant_id, "payment.refund.failed", "Refund", @refund.id)
      Result.new(refund: @refund, status: :ok)
    rescue AASM::InvalidTransition
      raise RefundError::InvalidTransition.new(from: @refund.status, to: "failed")
    end

    def event_name
      "payment.refund.failed"
    end

    def log_context
      {
        refund_uid: @refund.uid,
        transaction_uid: @refund.payment.uid
      }
    end
  end
end
