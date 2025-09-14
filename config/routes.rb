Rails.application.routes.draw do
  # Health check endpoints (for Docker/Kubernetes)
  get '/health', to: 'health#show'
  get '/health/detailed', to: 'health#detailed'
  get '/health/ready', to: 'health#ready'
  get '/health/live', to: 'health#live'

  # API routes
  namespace :api, { format: 'json' } do
    namespace :v1 do # バージョン1を表している
      namespace :user do
        resources :items
      end
      resources :name_judgment
    end
  end

  # Root route
  root 'application#index'
end
