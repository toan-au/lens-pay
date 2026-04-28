Rails.application.routes.draw do
  mount Rswag::Ui::Engine => "/api-docs"
  mount Rswag::Api::Engine => "/api-docs"

  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      resources :refunds, only: [ :index ]
      resources :payments, only: [ :index, :create, :show ], param: :uid do
        member do
          post :capture
        end
        resources :refunds, only: [ :index, :create ], controller: "payment_refunds"
      end
      resources :merchants, only: [ :create ] do
        collection do
          get :me
          patch :me, action: :update
        end
      end
    end
  end
end
