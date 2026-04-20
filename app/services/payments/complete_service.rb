module Payments
  class CompleteService < ApplicationService
    Result = Data.define(:transaction, :status)

    def initialize(transaction)
      @transaction = transaction
    end

    def perform
      @previous_status = @transaction.status
      @transaction.complete!
      Result.new(transaction: @transaction, status: :ok)
    rescue AASM::InvalidTransition
      raise PaymentError::InvalidTransition.new(from: @transaction.status, to: "succeeded")
    end

    def event_name
      "payment.succeeded"
    end

    def log_context
      {
        merchant_uid: @transaction.merchant.uid,
        transaction_uid: @transaction.uid,
        transaction_status: @previous_status,
        captured_amount: @transaction.captured_amount
      }
    end
  end
end
