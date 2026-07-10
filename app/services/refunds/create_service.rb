module Refunds
  class CreateService < ApplicationService
    Result = Data.define(:refund, :status)

    def initialize(transaction, params)
      @transaction = transaction
      @params = params
    end

    def perform
      existing_refund = find_existing
      return Result.new(refund: existing_refund, status: :ok) if existing_refund

      @refund = @transaction.refunds.new(@params)

      begin
        @transaction.with_lock do
          validate_refunded_amount!
          raise RefundError::ValidationFailed, @refund.errors.full_messages unless @refund.save
        end
      rescue ActiveRecord::RecordNotUnique
        # Lost a race with an identical concurrent request; honour the
        # idempotency contract by returning what the winner created.
        return Result.new(refund: find_existing, status: :ok)
      end

      SettleRefundJob.perform_later(@refund.id, request_id: Current.request_id)
      WebhookDeliveryJob.perform_later(@transaction.merchant_id, "payment.refund.created", "Refund", @refund.id, request_id: Current.request_id)

      Result.new(refund: @refund, status: :created)
    end

    def event_name
      "payment.refund.created"
    end

    def log_context
      {
        merchant_uid: @transaction.merchant.uid,
        transaction_uid: @transaction.uid,
        params: @params
      }
    end

    private

    def find_existing
      @transaction.refunds.find_by(idempotency_key: @params[:idempotency_key])
    end

    def validate_refunded_amount!
      raise RefundError::PaymentNotSucceeded unless @transaction.succeeded?
      raise RefundError::PaymentAlreadyRefunded if @transaction.refundable_amount == 0
      raise RefundError::AmountExceedsRefundable if @transaction.refundable_amount < @refund.amount
    end
  end
end
