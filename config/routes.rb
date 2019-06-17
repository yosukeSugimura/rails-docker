Rails.application.routes.draw do
  namespace :api, { format: 'json' } do
      namespace :v1 do # バージョン1を表している
        namespace :user do
          resources :items
        end
        resources :name_judgment
    end
  end
end
