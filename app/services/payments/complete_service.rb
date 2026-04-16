module Payments
  class CompleteService
    Result = Data.define(:transaction, :status)

    def self.call(transaction)
      new(transaction).call
    end

    def initialize(transaction)
      @transaction = transaction
    end

    def call
      @transaction.complete!
      Result.new(transaction: @transaction, status: :ok)
    rescue AASM::InvalidTransition
      raise PaymentError::InvalidTransition.new(from: @transaction.status, to: "succeeded")
    end
  end
end
