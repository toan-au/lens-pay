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

      existing = @merchant.transactions.find_by(idempotency_key: @params[:idempotency_key])
      return Result.new(transaction: existing, status: :ok) if existing

      transaction = @merchant.transactions.new(@params)

      raise PaymentError::ValidationFailed, transaction.errors.full_messages unless transaction.save

      AuthorizePaymentJob.perform_later(transaction.id)

      Result.new(transaction: transaction, status: :created)
    end
  end
end
