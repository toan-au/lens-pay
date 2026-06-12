Rails.application.routes.draw do
  mount Rswag::Ui::Engine => "/api-docs"
  mount Rswag::Api::Engine => "/api-docs"

  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      post "webhooks/ping", to: "webhooks#ping"
      get  "webhooks", to: "webhooks#index"
      post "webhooks/network/disputes", to: "network_disputes#create"
      post "webhooks/network/disputes/:uid/resolve", to: "network_disputes#resolve"
      post "webhooks/:merchant_uid", to: "webhooks#create"

      resources :customers, only: [ :index, :create, :show, :update, :destroy ], param: :uid
      resources :refunds, only: [ :index ]
      resources :payments, only: [ :index, :create, :show ], param: :uid do
        member do
          post :capture
          post :cancel
          get "webhook-events", to: "webhooks#payment_events"
        end
        resources :refunds, only: [ :index, :create ], controller: "payment_refunds"
      end

      resources :disputes, only: [ :index, :show ], param: :uid do
        member do
          patch :respond
        end
      end
      post "demo/sessions", to: "demo_sessions#create"

      resources :merchants, only: [ :create ] do
        collection do
          get :me
          patch :me, action: :update
        end
      end
    end
  end

  root to: "frontend#index"
  get "*path", to: "frontend#index"
end
