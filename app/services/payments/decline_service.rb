module Payments
  class DeclineService < ApplicationService
    Result = Data.define(:transaction, :status)

    def initialize(transaction)
      @transaction = transaction
    end

    def perform
      @previous_status = @transaction.status
      @transaction.decline!
      WebhookDeliveryJob.perform_later(@transaction.merchant_id, "payment.declined", "Transaction", @transaction.id)
      Result.new(transaction: @transaction, status: :ok)
    rescue AASM::InvalidTransition
      raise PaymentError::InvalidTransition.new(from: @transaction.status, to: "declined")
    end

    def event_name
      "payment.declined"
    end

    def log_context
      {
        merchant_uid: @transaction.merchant.uid,
        transaction_uid: @transaction&.uid,
        transaction_status: @previous_status,
        captured_amount: @transaction&.captured_amount
      }
    end
  end
end
