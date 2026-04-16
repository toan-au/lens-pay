module Merchants
    class FindService
        Result = Data.define(:merchant, :status)

        def self.call(uid)
            new(uid).call
        end


        def initialize(uid)
            @uid = uid
        end

        def call
            merchant = Merchant.find_by(uid: @uid)

            raise MerchantError::NotFound unless merchant
            Result.new(merchant: merchant, status: :ok)
        end
    end
end
