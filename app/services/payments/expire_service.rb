module Payments
  class ExpireService < ApplicationService
    Result = Data.define(:transaction, :status)

    def initialize(transaction)
      @transaction = transaction
    end

    def perform
      @transaction.with_lock do
        @transaction.expire!
      end
      WebhookDeliveryJob.perform_later(@transaction.merchant_id, "payment.expired", "Transaction", @transaction.id, request_id: Current.request_id)
      Result.new(transaction: @transaction, status: :ok)
    rescue AASM::InvalidTransition
      raise PaymentError::InvalidTransition.new(from: @transaction.status, to: "expired")
    end

    def event_name
      "payment.expired"
    end

    def log_context
      {
        merchant_uid: @transaction.merchant.uid,
        transaction_uid: @transaction.uid
      }
    end
  end
end
