module Customers
  class ListService < ApplicationService
    Result = Data.define(:customers, :next_cursor, :status)

    def initialize(merchant, cursor: nil, limit: nil)
      @merchant = merchant
      @cursor = cursor
      @limit = limit&.nonzero? || 25
    end

    def perform
      @customers = @merchant.customers.active

      if @cursor.present?
        cursor_record = @merchant.customers.find_by!(uid: @cursor)
        @customers = @customers.where("(created_at, id) < (?, ?)", cursor_record.created_at, cursor_record.id)
      end

      @customers = @customers.order(created_at: :desc, id: :desc).limit(@limit + 1)

      next_cursor = nil
      if @customers.length > @limit
        @customers = @customers.first(@limit)
        next_cursor = @customers.last.uid
      end

      Result.new(customers: @customers, next_cursor:, status: :ok)
    end

    def event_name
      "customer.listed"
    end

    def log_context
      { merchant_uid: @merchant.uid, customers_count: @customers.length }
    end
  end
end
