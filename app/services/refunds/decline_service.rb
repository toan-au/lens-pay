module Refunds
  class DeclineService < ApplicationService
    Result = Data.define(:refund, :status)

    def initialize(refund)
      @refund = refund
    end

    def perform
      @refund.decline!
      Result.new(refund: @refund, status: :ok)
    rescue AASM::InvalidTransition
      raise RefundError::InvalidTransition.new(from: @refund.status, to: "declined")
    end

    def event_name
      "refund.declined"
    end

    def log_context
      {
        refund_uid: @refund.uid,
        transaction_uid: @refund.payment.uid
      }
    end
  end
end
