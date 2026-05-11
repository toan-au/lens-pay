module Refunds
  class SucceedService < ApplicationService
    Result = Data.define(:refund, :status)

    def initialize(refund)
      @refund = refund
    end

    def perform
      @refund.with_lock do
        @refund.succeed!
      end
      WebhookDeliveryJob.perform_later(@refund.payment.merchant_id, "payment.refunded", "Refund", @refund.id)
      Result.new(refund: @refund, status: :ok)
    rescue AASM::InvalidTransition
      raise RefundError::InvalidTransition.new(from: @refund.status, to: "succeeded")
    end

    def event_name
      "payment.refunded"
    end

    def log_context
      {
        refund_uid: @refund.uid,
        transaction_uid: @refund.payment.uid
      }
    end
  end
end
