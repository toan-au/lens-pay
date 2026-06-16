module Webhooks
  class DisputePayloadService
    def self.call(dispute)
      new(dispute).call
    end

    def initialize(dispute)
      @dispute = dispute
    end

    def call
      {
        id:              @dispute.uid,
        resource:        "dispute",
        status:          @dispute.status,
        reason:          @dispute.reason,
        amount:          @dispute.amount,
        currency:        @dispute.currency,
        transaction_uid: @dispute.payment.uid,
        respond_by:      @dispute.respond_by.iso8601,
        resolved_at:     @dispute.resolved_at&.iso8601,
        created_at:      @dispute.created_at.iso8601
      }
    end
  end
end
