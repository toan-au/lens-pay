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
end
