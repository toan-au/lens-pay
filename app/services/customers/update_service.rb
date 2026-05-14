module Customers
  class UpdateService < ApplicationService
    Result = Data.define(:customer, :status)

    PERMITTED = %i[name email metadata].freeze

    def initialize(merchant, uid, params)
      @merchant = merchant
      @uid = uid
      @params = params.slice(*PERMITTED)
    end

    def perform
      @customer = @merchant.customers.active.find_by(uid: @uid)
      raise CustomerError::NotFound unless @customer

      raise CustomerError::ValidationFailed, @customer.errors.full_messages unless @customer.update(@params)

      Result.new(customer: @customer, status: :ok)
    end

    def event_name
      "customer.updated"
    end

    def log_context
      { merchant_uid: @merchant.uid, customer_uid: @uid }
    end
  end
end
