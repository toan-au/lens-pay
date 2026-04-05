class Api::V1::PaymentsController < ApplicationController


    def create 
        @transaction = Transaction.create(transaction_params)
        render json: @transaction, status: 200
    end

    def show 
        render json: {}, status: 200
    end

    def update

    end

    private
        def transaction_params
            params.require(:payment).permit([ :amount, :currency, :idempotency_key ])
        end
end
