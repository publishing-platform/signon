Rails.application.routes.draw do
  use_doorkeeper
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
      get :edit_suspension
      patch :update_suspension
      patch :unlock
    end
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  root to: "root#index"
end
