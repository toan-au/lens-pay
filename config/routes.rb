Rails.application.routes.draw do

  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      resources :payments, only: [:create, :show, :update], param: :idempotency_key
    end
  end
end
