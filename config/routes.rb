Rails.application.routes.draw do
  use_doorkeeper do
    controllers authorizations: "signin_required_authorizations"
    skip_controllers :applications, :authorized_applications, :token_info
  end

  devise_for :users, controllers: {
    invitations: "users/invitations",
    sessions: "users/sessions",
    passwords: "users/passwords",
    confirmations: "users/confirmations",
  }

  devise_scope :user do
    put "users/confirmation" => "users/confirmations#update"
    put "users/invitation/resend/:id" => "users/invitations#resend", :as => "resend_user_invitation"
  end

  resource :two_factor_authentication,
           only: %i[show update],
           path: "/users/two_factor_authentication",
           controller: "users/two_factor_authentication" do
    resource :session, only: %i[new create], controller: "users/two_factor_authentication_session"

    member { get :prompt }
  end

  resources :users, except: %i[show] do
    member do
      get :edit_email_or_password
      patch :update_email
      patch :update_password
      put :resend_email_change
      delete :cancel_email_change
      patch :unlock
      patch :reset_2fa
    end

    resource :suspensions, only: %i[edit update]

    resources :applications, only: %i[index show], controller: "users/applications" do
      resource :permissions, only: %i[edit update], controller: "users/permissions"
      resource :signin_permission, only: %i[create destroy], controller: "users/signin_permissions" do
        get :delete
      end
    end
  end

  get "user", to: "oauth_users#show"

  resources :oauth_applications, except: %i[show destroy] do
    resources :permissions, except: %i[show destroy]
  end

  resources :api_users, only: %i[new create index edit update] do
    resources :applications, only: %i[index], controller: "api_users/applications" do
      resource :permissions, only: %i[edit update], controller: "api_users/permissions"
    end
    member do
      get :manage_tokens
    end
    resources :authorisations, only: %i[new create edit], controller: "api_users/authorisations" do
      member do
        post :revoke
      end
    end
  end

  get "/signin-required" => "root#signin_required"

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  root to: "root#index"
end
