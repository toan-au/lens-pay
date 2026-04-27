module Refunds
  class SucceedService < ApplicationService
    Result = Data.define(:refund, :status)

    def initialize(refund)
      @refund = refund
    end

    def perform
      @refund.succeed!
      WebhookDeliveryJob.perform_later(@refund.payment.merchant_id, "refund.succeeded", "Refund", @refund.id)
      Result.new(refund: @refund, status: :ok)
    rescue AASM::InvalidTransition
      raise RefundError::InvalidTransition.new(from: @refund.status, to: "succeeded")
    end

    def event_name
      "refund.succeeded"
    end

    def log_context
      {
        refund_uid: @refund.uid,
        transaction_uid: @refund.payment.uid
      }
    end
  end
end
