module Webhooks
  class PaymentPayloadService
    def self.call(transaction)
      new(transaction).call
    end

    def initialize(transaction)
      @transaction = transaction
    end

    def call
      {
        id: @transaction.uid,
        resource: "payment",
        status: @transaction.status,
        amount: @transaction.amount,
        currency: @transaction.currency,
        captured_amount: @transaction.captured_amount,
        idempotency_key: @transaction.idempotency_key,
        merchant_uid: @transaction.merchant.uid,
        created_at: @transaction.created_at.iso8601
      }
    end
  end
end
