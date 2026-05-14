module CustomerError
  class NotFound < StandardError
    def initialize
      super("Customer not found")
    end
  end

  class ValidationFailed < StandardError
    attr_reader :messages

    def initialize(messages)
      @messages = messages
      super(messages.join(", "))
    end
  end
end
