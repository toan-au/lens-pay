module Payments
    class FindService
        def initialize(params)
            @params = params
        end

        def self.call(params)
            new(params).call
        end

        def call(idempotency_key)
            existing = Transaction.find_by(idempotency_key: idempotency_key)
            raise Payments::NotFound unless existing

            
        end
    end
end
