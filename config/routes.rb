# frozen_string_literal: true

Rails.application.routes.draw do
  use_doorkeeper do
    # it accepts :authorizations, :tokens, :token_info, :applications and :authorized_applications
    controllers authorizations: 'oauth_applications'
  end
  use_doorkeeper_openid_connect
  mount Peek::Railtie => '/peek'
  get 'admin' => 'admin/dashboard#index', as: :admin_dashboard
  namespace :admin do
    # get 'dashboard/index'
    resources :groups
    resources :users
    resources :permissions
    resources :applications
    resources :saml_service_providers
    get :settings, to: 'settings#index'
    post :settings, to: 'settings#update'
  end

  devise_for :users, controllers: {
    registrations: :registrations,
    sessions: :sessions
  }

  authenticated do
    root to: 'profile#show', as: :authenticated_root
  end

  scope '(:locale)', locale: /en/ do
    root to: 'pages#home'
  end

  get 'users/2fa', to: 'users#new_2fa', as: 'new_user_2fa_registration'
  post 'users/2fa', to: 'users#create_2fa', as: 'user_two_factor_auth'
  post 'users/2fa/codes', to: 'users#codes', as: 'user_2fa_codes'
  delete '/users/2fa', to: 'users#disable_2fa'
  # SAMLv2 IdP
  get '/saml/auth' => 'saml_idp#create'
  post '/saml/auth' => 'saml_idp#create'
  get '/saml/metadata' => 'saml_idp#show'
  match '/saml/logout' => 'saml_idp#logout', via: %i[get post delete]

  get 'auth/basic/:permission_name', to: 'basic_auth#create'

  namespace :profile do
    get 'authentication_devices', to: 'authentication_devices#index', as: 'authentication_devices'
    get 'account_activity', to: 'account_activity#index', as: 'account_activity'
  end
end
