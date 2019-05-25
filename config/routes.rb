Rails.application.routes.draw do
  devise_for :users
  require "sidekiq/web"
  mount Sidekiq::Web => '/sidekiq'

  scope '(:locale)', locale: /fr/ do
    root to: 'pages#home'
  end
end