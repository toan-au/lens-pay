class Api::V1::PaymentsController < ApplicationController
    def create 
        params.require([:amount, :currency, :idempotency_key])

        unless ["JPY", "USD", "EUR"].include?(transaction_params[:currency])
            return render json: { error: "Invalid currency" }, status: :bad_request
        end

        existing = Transaction.find_by(idempotency_key: transaction_params[:idempotency_key])
        return render json: existing, status: :ok if existing

        @transaction = Transaction.new(transaction_params)

        if @transaction.save
            render json: @transaction, status: :created
        else
            render json: { errors: @transaction.errors.full_messages }, status: :unprocessable_entity
        end
    end

    def show 
        render json: {}, status: 200
    end

    def update

    end

    private
        def transaction_params
            params.permit(:amount, :currency, :idempotency_key)
        end
end
