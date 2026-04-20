module Refunds
    class CreateService
        Result = Data.define(:refund, :status)

        def self.call(transaction, params)
            new(transaction, params).call
        end

        def initialize(transaction, params)
            @transaction = transaction
            @params = params
        end

        def call
            @refund = @transaction.refunds.new(@params)

            validate_refunded_amount!

            raise RefundError::ValidationFailed, @refund.errors.full_messages unless @refund.save

            Result.new(refund: @refund, status: :created)
        end

        private
        def validate_refunded_amount!
            raise RefundError::PaymentNotSucceeded unless @transaction.succeeded?
            raise RefundError::PaymentAlreadyRefunded if @transaction.refundable_amount == 0
            raise RefundError::AmountExceedsRefundable if @transaction.refundable_amount < @refund.amount
        end
    end
end
