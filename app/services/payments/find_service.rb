module Payments
  class FindService
    Result = Data.define(:transaction, :status)

    def self.call(merchant, uid)
      new(merchant, uid).call
    end

    def initialize(merchant, uid)
      @merchant = merchant
      @uid = uid
    end

    def call
      transaction = @merchant.transactions.find_by(uid: @uid)
      raise PaymentError::NotFound unless transaction

      Result.new(transaction: transaction, status: :ok)
    end
  end
end
