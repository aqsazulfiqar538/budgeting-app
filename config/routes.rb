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
        resources :comments, controller: "comments", only: [ :index, :create, :destroy ]
      end
      resources :categories, only: [ :index, :create ]

      resources :ledger, only: [ :index, :show ], controller: "ledger"
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

      get "/users/me", to: "users#me"
      patch "/users/me", to: "users#update_me"
      get "/users/search", to: "users#search"
      resources :users, only: [ :show ]

      resources :groups do
        member do
          post :restore
        end
        resources :members, controller: "group_members", only: [ :create, :destroy ]
      end

      resources :friends, only: [ :index, :show, :create, :destroy ] do
        collection do
          get :requests, to: "friend_requests#index"
        end
        member do
          patch :accept, to: "friend_requests#accept"
          patch :reject, to: "friend_requests#reject"
        end
      end
    end
  end
end
