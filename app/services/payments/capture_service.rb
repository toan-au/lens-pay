module Payments
  class CaptureService < ApplicationService
    Result = Data.define(:transaction, :status)

    def initialize(transaction, captured_amount: nil)
      @transaction = transaction
      @captured_amount = captured_amount || transaction.amount
    end

    def perform
      validate_captured_amount!

      @transaction.with_lock do
        @previous_status = @transaction.status

        @transaction.capture!
        @transaction.update!(captured_amount: @captured_amount)
      end

      SettlePaymentJob.perform_later(@transaction.id)

      Result.new(transaction: @transaction, status: :ok)
    rescue AASM::InvalidTransition
      raise PaymentError::InvalidTransition.new(from: @transaction.status, to: "processing")
    end

    def event_name
      "payment.captured"
    end

    def log_context
      {
        merchant_uid: @transaction.merchant.uid,
        transaction_uid: @transaction.uid,
        transaction_status: @previous_status,
        captured_amount: @transaction.captured_amount
      }
    end

    private

    def validate_captured_amount!
      raise PaymentError::CapturedAmountExceedsAuthorized if @captured_amount > @transaction.amount
      raise PaymentError::ValidationFailed, [ "Captured amount must be greater than 0" ] if @captured_amount <= 0
    end
  end
end
