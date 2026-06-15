module Disputes
  class ListService
    Result = Data.define(:disputes, :next_cursor, :status)

    def initialize(merchant, cursor: nil, status: nil, limit: nil)
      @merchant = merchant
      @cursor   = cursor
      @status   = status
      @limit    = limit&.nonzero? || 25
    end

    def call
      @disputes = @merchant.disputes

      @disputes = @disputes.where(status: @status) if @status.present?

      if @cursor.present?
        cursor_record = @merchant.disputes.find_by!(uid: @cursor)
        @disputes = @disputes.where("(created_at, id) < (?, ?)", cursor_record.created_at, cursor_record.id)
      end

      @disputes = @disputes.order(created_at: :desc, id: :desc).limit(@limit + 1)

      next_cursor = nil
      if @disputes.length > @limit
        @disputes = @disputes.first(@limit)
        next_cursor = @disputes.last.uid
      end

      Result.new(disputes: @disputes, next_cursor:, status: :ok)
    end

    def self.call(...)
      new(...).call
    end
  end
end
