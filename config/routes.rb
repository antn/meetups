Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Authentication (OmniAuth / Concat).
  # The request phase (POST /auth/:provider) is handled by the OmniAuth middleware.
  match "/auth/:provider/callback", to: "sessions#create", via: [ :get, :post ]
  get "/auth/failure", to: "sessions#failure"
  delete "/logout", to: "sessions#destroy", as: :logout

  get "/my-schedule", to: "schedules#show", as: :my_schedule
  resources :meetups, only: %i[new create show edit update] do
    member do
      patch :cancel
    end
    resource :attendance, only: %i[create destroy]
  end

  # Admin-only tooling, scoped to the current event. Gated on site_admin in
  # Stafftools::ApplicationController.
  namespace :stafftools do
    root "dashboard#index"

    resources :events, except: :show do
      member do
        patch :activate
      end
    end

    resources :scheduling_days, except: :show
    resources :locations, except: :show
    resources :tags, except: :show

    resources :users, only: :index do
      member do
        patch :suspend
        patch :unsuspend
      end
    end

    resources :meetups, only: %i[index show edit update] do
      member do
        patch :approve
        patch :reject
        patch :cancel
        patch :unapprove
      end
    end
  end

  root "meetups#index"
end
