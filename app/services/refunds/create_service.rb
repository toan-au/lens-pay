module Refunds
    class CreateService
        Result = Data.define(:refund, :status)

        def self.call(params, transaction)
            new(params, transaction).call
        end

        def initialize(params, transaction)
            @params = params
            @transaction = transaction
        end

        def call
            @refund = Refund.new(@params)
            @refund.payment = @transaction

            validate_refunded_amount!

            raise RefundError::ValidationFailed, @refund.errors.full_messages unless @refund.save

            Result.new(refund: @refund, status: :created)
        end

        private
        def validate_refunded_amount!
            raise RefundError::PaymentNotSucceeded unless @transaction.succeeded?
            raise RefundError::PaymentAlreadyRefunded if @transaction.refundable_amount == 0
            raise RefundError::InvalidRefund if @transaction.refundable_amount < @refund.amount
        end
    end
end
