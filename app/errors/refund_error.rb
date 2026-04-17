module RefundError
    class InvalidRefund < StandardError
        def initialize
            super("Refund amount is Invalid")
        end
    end
    class ValidationFailed < StandardError
        attr_reader :messages

        def initialize(messages)
            @messages = messages
            super(messages.join(", "))
        end
    end
    class PaymentNotSucceeded < StandardError
        def initialize
            super("Payment has not yet succeeded")
        end
    end
    class PaymentAlreadyRefunded < StandardError
        def initialize
            super("Payment has already been refunded")
        end
    end
end
