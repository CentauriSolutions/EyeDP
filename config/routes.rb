# frozen_string_literal: true

Rails.application.routes.draw do
  get 'admin' => 'admin/dashboard#index', as: :admin_dashboard
  namespace :admin do
    # get 'dashboard/index'
    resources :groups
    resources :users
    resources :permissions
    resources :saml_service_providers
    get :settings, to: 'settings#index'
    post :settings, to: 'settings#update'
  end

  devise_for :users
  require 'sidekiq/web'
  mount Sidekiq::Web => '/sidekiq'

  scope '(:locale)', locale: /en/ do
    root to: 'pages#home'
  end

  # SAMLv2 IdP
  get '/saml/auth' => 'saml_idp#create'
  post '/saml/auth' => 'saml_idp#create'
  get '/saml/metadata' => 'saml_idp#show'

  get 'auth/basic/:permission_name', to: 'basic_auth#create'
end
