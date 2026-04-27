module Webhooks
  class RefundPayloadService
    def self.call(refund)
      new(refund).call
    end

    def initialize(refund)
      @refund = refund
    end

    def call
      {
        id: @refund.uid,
        resource: "refund",
        status: @refund.status,
        amount: @refund.amount,
        currency: @refund.payment.currency,
        transaction_uid: @refund.payment.uid,
        created_at: @refund.created_at.iso8601
      }
    end
  end
end
