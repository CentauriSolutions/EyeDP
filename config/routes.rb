# frozen_string_literal: true

require 'sidekiq/web'

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
    resources :groups do
      get :email, to: 'groups#email'
    end
    resources :users do
      post :reset_password, to: 'users#reset_password'
    end
    resources :custom_userdata_types
    resources :custom_group_data_types
    resources :permissions
    resources :applications do
      post :renew_secret, to: 'applications#renew_secret'
    end
    resources :saml_service_providers
    resources :audits, only: %i[index show]
    get :settings, to: 'settings#index'
    post :settings, to: 'settings#update'
    # namespace :settings do
    get 'settings/openid_connect', to: 'settings#openid_connect'
    get 'settings/saml', to: 'settings#saml'
    get 'settings/branding', to: 'settings#branding'
    get 'settings/templates', to: 'settings#templates'
    # end

    get 'jobs', to: 'dashboard#jobs'

    authenticate :user, ->(user) { user.admin? || user.operator? } do
      mount Sidekiq::Web => '/sidekiq'
    end
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
  match 'users/2fa/codes', to: 'users#codes', as: 'user_2fa_codes', via: %i[get post]
  delete '/users/2fa', to: 'users#disable_2fa'
  # SAMLv2 IdP
  get '/saml/auth' => 'saml_idp#create'
  post '/saml/auth' => 'saml_idp#create'
  get '/saml/metadata' => 'saml_idp#show'
  match '/saml/logout' => 'saml_idp#logout', via: %i[get post delete]

  get 'auth/basic/:permission_name', to: 'basic_auth#create'

  namespace :profile do
    get 'authentication_devices', to: 'authentication_devices#index'
    get 'account_activity', to: 'account_activity#index'
    get 'additional_properties', to: 'additional_properties#index'
    post 'additional_properties', to: 'additional_properties#update'
  end
end
