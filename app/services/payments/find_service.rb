module Payments
  class FindService
    Result = Data.define(:transaction, :status)

    def self.call(idempotency_key)
      new(idempotency_key).call
    end

    def initialize(idempotency_key)
      @idempotency_key = idempotency_key
    end

    def call
      transaction = Transaction.find_by(idempotency_key: @idempotency_key)
      raise PaymentError::NotFound unless transaction

      Result.new(transaction: transaction, status: :ok)
    end
  end
end
