module Payments
  class CreateService
    Result = Data.define(:transaction, :status)

    def self.call(merchant, params)
      new(merchant, params).call
    end

    def initialize(merchant, params)
      @merchant = merchant
      @params = params
    end

    def call
      raise PaymentError::InvalidCurrency unless Money::Currency.find(@params[:currency])

      existing = @merchant.transactions.find_by(idempotency_key: @params[:idempotency_key])
      return Result.new(transaction: existing, status: :ok) if existing

      transaction = @merchant.transactions.new(@params)

      raise PaymentError::ValidationFailed, transaction.errors.full_messages unless transaction.save

      AuthorizePaymentJob.perform_later(transaction.id)

      Result.new(transaction: transaction, status: :created)
    end
  end
end
