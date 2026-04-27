module WebhookError
  class DeliveryFailed < StandardError
    def initialize(reason)
      super("Webhook delivery failed: #{reason}")
    end
  end
end
