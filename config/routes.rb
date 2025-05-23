Rails.application.routes.draw do
  resources :meetups
  root to: "meetups#index"

  get "/auth/concat/callback", to: "sessions#create"
  delete "/logout", to: "sessions#destroy"

  get "/stafftools", to: "stafftools#index", as: :stafftools

  resource :stafftools, module: :stafftools do
    resources :meetup_areas
    resources :meetup_days
    resources :meetups
  end

  resource :rules, only: [:show]
  resource :map, only: [:show]

  get "_ping", to: "rails/health#show", as: :rails_health_check
end
