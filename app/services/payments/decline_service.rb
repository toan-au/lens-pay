module Payments
  class DeclineService
    Result = Data.define(:transaction, :status)

    def self.call(transaction)
      new(transaction).call
    end

    def initialize(transaction)
      @transaction = transaction
    end

    def call
      @transaction.decline!
      Result.new(transaction: @transaction, status: :ok)
    rescue AASM::InvalidTransition
      raise PaymentError::InvalidTransition.new(from: @transaction.status, to: "declined")
    end
  end
end
