Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      devise_for :users,
        path: "",
        path_names: {
          sign_in: "users/log_in",
          sign_out: "users/log_out",
          registration: "users"
        },
        controllers: {
          sessions: "api/v1/users/sessions",
          registrations: "api/v1/users/registrations"
        }

      get "/dashboard", to: "dashboard#index"
      resources :expenses
    end
  end
end
