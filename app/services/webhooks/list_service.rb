module Webhooks
  class ListService
    Result = Data.define(:webhook_events, :next_cursor, :status)

    def initialize(merchant, cursor: nil, limit: nil)
      @merchant = merchant
      @cursor   = cursor
      @limit    = limit&.nonzero? || 25
    end

    def call
      events = @merchant.webhook_events

      if @cursor.present?
        # WebhookEvent has no uid column; its integer id is the public identifier.
        cursor_record = @merchant.webhook_events.find(@cursor)
        events = events.where("(created_at, id) < (?, ?)", cursor_record.created_at, cursor_record.id)
      end

      events = events.order(created_at: :desc, id: :desc).limit(@limit + 1)

      next_cursor = nil
      if events.length > @limit
        events = events.first(@limit)
        next_cursor = events.last.id
      end

      Result.new(webhook_events: events, next_cursor:, status: :ok)
    end

    def self.call(...)
      new(...).call
    end
  end
end
