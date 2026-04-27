module Payments
  class AuthorizeService < ApplicationService
    Result = Data.define(:transaction, :status)

    def initialize(transaction)
      @transaction = transaction
    end

    def perform
      @transaction.authorize!
      WebhookDeliveryJob.perform_later(@transaction.merchant_id, "payment.authorized", "Transaction", @transaction.id)
      Result.new(transaction: @transaction, status: :ok)
    rescue AASM::InvalidTransition
      raise PaymentError::InvalidTransition.new(from: @transaction.status, to: "authorized")
    end

    def event_name
      "payment.authorized"
    end

    def log_context
      {
        merchant_uid: @transaction.merchant.uid,
        transaction_uid: @transaction.uid
      }
    end
  end
end
