module MerchantError
  class ValidationFailed < StandardError
    attr_reader :messages

    def initialize(messages)
      @messages = messages
      super(messages.join(", "))
    end
  end

  class NotFound < StandardError
    def initialize
      super("Merchant not found")
    end
  end
end
