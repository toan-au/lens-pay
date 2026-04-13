module Payments
  class CreateService
    Result = Data.define(:transaction, :status)

    def self.call(params, merchant)
      new(params, merchant).call
    end

    def initialize(params, merchant)
      @params = params
      @merchant = merchant
    end

    def call
      raise PaymentError::InvalidCurrency unless Money::Currency.find(@params[:currency])

      existing = Transaction.find_by(idempotency_key: @params[:idempotency_key])
      return Result.new(transaction: existing, status: :ok) if existing

      transaction = Transaction.new(@params.merge(merchant: @merchant))

      raise PaymentError::ValidationFailed, transaction.errors.full_messages unless transaction.save

      Result.new(transaction: transaction, status: :created)
    end
  end
end
