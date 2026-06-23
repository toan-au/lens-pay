module Payments
  class CancelService < ApplicationService
    Result = Data.define(:transaction, :status)

    def initialize(transaction)
      @transaction = transaction
    end

    def perform
      @transaction.with_lock do
        @previous_status = @transaction.status
        @transaction.cancel!
      end
      WebhookDeliveryJob.perform_later(@transaction.merchant_id, "payment.cancelled", "Transaction", @transaction.id, request_id: Current.request_id)
      Result.new(transaction: @transaction, status: :ok)
    rescue AASM::InvalidTransition
      raise PaymentError::InvalidTransition.new(from: @transaction.status, to: "cancelled")
    end

    def event_name
      "payment.cancelled"
    end

    def log_context
      {
        merchant_uid: @transaction.merchant.uid,
        transaction_uid: @transaction.uid,
        transaction_status: @previous_status
      }
    end
  end
end
