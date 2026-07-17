module Payments
  class ConfirmService < ApplicationService
    Result = Data.define(:transaction, :status)

    def initialize(transaction)
      @transaction = transaction
    end

    def perform
      @transaction.with_lock do
        @transaction.confirm!
        # Cash is always paid in full. no partial capture for konbini or bank transfer.
        @transaction.update!(captured_amount: @transaction.amount)
      end

      SettlePaymentJob.perform_later(@transaction.id, request_id: Current.request_id)
      WebhookDeliveryJob.perform_later(@transaction.merchant_id, "payment.confirmed", "Transaction", @transaction.id, request_id: Current.request_id)

      Result.new(transaction: @transaction, status: :ok)
    rescue AASM::InvalidTransition
      raise PaymentError::InvalidTransition.new(from: @transaction.status, to: "processing")
    end

    def event_name
      "payment.confirmed"
    end

    def log_context
      {
        merchant_uid: @transaction.merchant.uid,
        transaction_uid: @transaction.uid,
        payment_method: @transaction.payment_method
      }
    end
  end
end
