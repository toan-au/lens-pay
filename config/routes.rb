Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      resources :payments, only: [ :create, :show ], param: :uid do
        member do
          post :authorize
          post :capture
          post :complete
          post :decline
        end
      end
      resources :merchants, only: [ :create, :show ], param: :uid
    end
  end
end
