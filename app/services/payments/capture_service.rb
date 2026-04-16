module Payments
  class CaptureService
    Result = Data.define(:transaction, :status)

    def self.call(transaction, captured_amount: nil)
      new(transaction, captured_amount:).call
    end

    def initialize(transaction, captured_amount:)
      @transaction = transaction
      @captured_amount = captured_amount || transaction.amount
    end

    def call
      validate_captured_amount!

      @transaction.capture!
      @transaction.update!(captured_amount: @captured_amount)

      Result.new(transaction: @transaction, status: :ok)
    rescue AASM::InvalidTransition
      raise PaymentError::InvalidTransition.new(from: @transaction.status, to: "processing")
    end

    private

    def validate_captured_amount!
      raise PaymentError::CapturedAmountExceedsAuthorized if @captured_amount > @transaction.amount
      raise PaymentError::ValidationFailed, ["Captured amount must be greater than 0"] if @captured_amount <= 0
    end
  end
end
