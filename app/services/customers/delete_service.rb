module Customers
  class DeleteService < ApplicationService
    Result = Data.define(:customer, :status)

    def initialize(merchant, uid)
      @merchant = merchant
      @uid = uid
    end

    def perform
      @customer = @merchant.customers.active.find_by(uid: @uid)
      raise CustomerError::NotFound unless @customer

      @customer.delete!

      Result.new(customer: @customer, status: :ok)
    end

    def event_name
      "customer.deleted"
    end

    def log_context
      { merchant_uid: @merchant.uid, customer_uid: @uid }
    end
  end
end
