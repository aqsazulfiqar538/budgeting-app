Rails.application.routes.draw do
  devise_for :users

  authenticated :user do
    root "dashboard#index", as: :authenticated_root
  end

  unauthenticated do
    root to: redirect("/users/sign_in")
  end

  get "/dashboard", to: "dashboard#index", as: :dashboard

  resources :recommendations, only: [:index, :show, :new, :create]
end