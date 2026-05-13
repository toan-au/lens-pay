module Payments
  class CreateService < ApplicationService
    Result = Data.define(:transaction, :status)

    def initialize(merchant, params)
      @merchant = merchant
      @params = params
    end

    def perform
      raise PaymentError::InvalidCurrency unless Money::Currency.find(@params[:currency])

      existing = @merchant.transactions.find_by(idempotency_key: @params[:idempotency_key])
      return Result.new(transaction: existing, status: :ok) if existing

      transaction_params = @params.except(:customer_uid)
      if @params[:customer_uid]
        customer = @merchant.customers.active.find_by(uid: @params[:customer_uid])
        raise CustomerError::NotFound unless customer
        transaction_params = transaction_params.merge(customer:)
      end

      @transaction = @merchant.transactions.new(transaction_params)

      raise PaymentError::ValidationFailed, @transaction.errors.full_messages unless @transaction.save

      AuthorizePaymentJob.perform_later(@transaction.id)

      Result.new(transaction: @transaction, status: :created)
    end

    def event_name
      "payment.created"
    end

    def log_context
      {
        merchant_uid: @merchant.uid,
        transaction_uid: @transaction&.uid,
        params: @params
      }
    end
  end
end
