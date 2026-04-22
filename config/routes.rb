Rails.application.routes.draw do
  mount Rswag::Ui::Engine => "/api-docs"
  mount Rswag::Api::Engine => "/api-docs"

  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      get "refunds/index"
      resources :payments, only: [ :index, :create, :show ], param: :uid do
        member do
          post :authorize
          post :capture
          post :complete
          post :decline
        end
        resources :refunds, only: [ :index, :create ], controller: "payment_refunds"
      end
      resources :merchants, only: [ :create, :show ], param: :uid
      resources :refunds, only: [ :index ]
    end
  end
end
