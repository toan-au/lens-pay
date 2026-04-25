module Refunds
  class CreateService < ApplicationService
    Result = Data.define(:refund, :status)

    def initialize(transaction, params)
      @transaction = transaction
      @params = params
    end

    def perform
      existing_refund = @transaction.refunds.find_by(idempotency_key: @params[:idempotency_key])
      return Result.new(refund: existing_refund, status: :ok) if existing_refund

      @refund = @transaction.refunds.new(@params)

      @transaction.with_lock do
        validate_refunded_amount!
        raise RefundError::ValidationFailed, @refund.errors.full_messages unless @refund.save
      end

      SettleRefundJob.perform_later(@refund.id)

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
