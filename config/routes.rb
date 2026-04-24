Rails.application.routes.draw do
  devise_for :users,
    path: "api/v1",
    path_names: {
      sign_in: "login",
      sign_out: "logout",
      registration: "signup"
    },
    controllers: {
      sessions: "api/v1/sessions",
      registrations: "api/v1/registrations",
      passwords: "api/v1/passwords",
      confirmations: "api/v1/confirmations"
    },
    defaults: { format: :json }

  namespace :api do
    namespace :v1 do
      get "/dashboard", to: "dashboard#index"
      resources :expenses do
        resources :comments, only: [ :index, :create, :destroy ]
      end
      resources :categories, only: [ :index, :create ]

      resources :ledger, only: [ :index, :show ]
      resources :repayments, only: [] do
        member do
          patch :settle
        end
      end
      resources :notifications, only: [ :index ] do
        collection do
          patch :mark_read
        end
      end

      resources :users, only: [:show] do
        collection do
          get :user_profile
          patch :user_profile, to: "users#update_profile"
          get :search
        end
      end

      resources :groups do
        resources :members, controller: "group_members", only: [ :create, :destroy ]
      end

      resources :friendships, only: [ :index, :show, :create, :destroy ] do
        collection do
          get :requests
        end
        member do
          patch :accept
          patch :reject
        end
      end
    end
  end
end
