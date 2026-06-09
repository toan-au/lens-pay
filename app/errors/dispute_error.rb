module DisputeError
  class ValidationFailed < StandardError
    attr_reader :messages

    def initialize(messages)
      @messages = messages
      super(messages.join(", "))
    end
  end

  class InvalidPayment < StandardError
    def initialize
      super("Payment is not valid")
    end
  end

  class MismatchedCurrency < StandardError
    def initialize
      super("Currency mismatched with payment")
    end
  end

  class InvalidReason < StandardError
    def initialize
      super("Invalid reason code")
    end
  end

  class AlreadyDisputed < StandardError
    def initialize
      super("Payment has an existing dispute")
    end
  end

  class RespondByPassed < StandardError
    def initialize
      super("RespondBy date has passed")
    end
  end

  class NotFound < StandardError
    def initialize
      super("Dispute not found")
    end
  end

  class InvalidTransition < StandardError
    def initialize(from:, to:)
      super("Cannot transition dispute from '#{from}' to '#{to}'")
    end
  end
end
