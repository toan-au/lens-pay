module Refunds
  class CreateService < ApplicationService
    Result = Data.define(:refund, :status)

    def initialize(transaction, params)
      @transaction = transaction
      @params = params
    end

    def perform
      @refund = @transaction.refunds.new(@params)

      validate_refunded_amount!

      raise RefundError::ValidationFailed, @refund.errors.full_messages unless @refund.save

      Result.new(refund: @refund, status: :created)
    end

    def event_name
      "refund.created"
    end

    def log_context
      {
        merchant_uid: @transaction.merchant.uid,
        transaction_uid: @transaction.uid,
        params: @params
      }
    end

    private
    def validate_refunded_amount!
      raise RefundError::PaymentNotSucceeded unless @transaction.succeeded?
      raise RefundError::PaymentAlreadyRefunded if @transaction.refundable_amount == 0
      raise RefundError::AmountExceedsRefundable if @transaction.refundable_amount < @refund.amount
    end
  end
end
