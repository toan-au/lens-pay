module Payments
  class FindService
    Result = Data.define(:transaction, :status)

    def self.call(uid)
      new(uid).call
    end

    def initialize(uid)
      @uid = uid
    end

    def call
      transaction = Transaction.find_by(uid: @uid)
      raise PaymentError::NotFound unless transaction

      Result.new(transaction: transaction, status: :ok)
    end
  end
end
