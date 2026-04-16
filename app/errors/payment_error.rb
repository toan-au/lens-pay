module PaymentError
  class InvalidCurrency < StandardError
    def initialize
      super("Invalid currency")
    end
  end

  class ValidationFailed < StandardError
    attr_reader :messages

    def initialize(messages)
      @messages = messages
      super(messages.join(", "))
    end
  end

  class NotFound < StandardError
    def initialize
      super("Payment not found")
    end
  end

  class InvalidTransition < StandardError
    def initialize(from:, to:)
      super("Cannot transition payment from '#{from}' to '#{to}'")
    end
  end

  class CapturedAmountExceedsAuthorized < StandardError
    def initialize
      super("Captured amount cannot exceed the authorized amount")
    end
  end
end
