module Webhooks
  class BuildPayloadService
    def self.call(event_type:, resource:, event_id:)
      new(event_type:, resource:, event_id:).call
    end

    def initialize(event_type:, resource:, event_id:)
      @event_type = event_type
      @resource = resource
      @event_id = event_id
    end

    def call
      {
        id: @event_id,
        type: @event_type,
        resource: "event",
        created_at: Time.current.iso8601,
        data: build_data
      }.to_json
    end

    private

    def build_data
      case @resource
      when Transaction then PaymentPayloadService.call(@resource)
      when Refund      then RefundPayloadService.call(@resource)
      end
    end
  end
end
