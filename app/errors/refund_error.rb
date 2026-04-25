module RefundError
  class ValidationFailed < StandardError
    attr_reader :messages

    def initialize(messages)
      @messages = messages
      super(messages.join(", "))
    end
  end
  class AmountExceedsRefundable < StandardError
    def initialize
      super("Refund amount is Invalid")
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

  class InvalidTransition < StandardError
    def initialize(from:, to:)
      super("Cannot transition refund from '#{from}' to '#{to}'")
    end
  end
end
