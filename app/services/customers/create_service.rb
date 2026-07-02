module Customers
  class CreateService < ApplicationService
    Result = Data.define(:customer, :status)

    def initialize(merchant, params)
      @merchant = merchant
      @params = params
    end

    def perform
      @customer = @merchant.customers.new(@params)

      raise CustomerError::ValidationFailed, @customer.errors.full_messages unless @customer.save

      Result.new(customer: @customer, status: :created)
    end

    def event_name
      "customer.created"
    end

    def log_context
      {
        merchant_uid: @merchant.uid,
        customer_uid: @customer&.uid
      }
    end
  end
end
