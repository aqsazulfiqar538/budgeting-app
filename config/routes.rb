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
      registrations: "api/v1/registrations"
    },
    defaults: { format: :json }

  namespace :api do
    namespace :v1 do
      get "/dashboard", to: "dashboard#index"
      resources :expenses
    end
  end
end