class ApplicationController < ActionController::Base
  include Pundit::Authorization
  include TwoFactorAuthenticationHelper

  before_action :handle_two_factor_authentication
  after_action :verify_authorized, unless: :devise_controller?

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

private

  def redirect_to_prior_flow(args = {})
    redirect_to stored_location_for(:user) || :root, args
  end

  def user_not_authorized(_exception)
    flash[:alert] = "You do not have permission to perform this action."
    redirect_to root_path
  end
end
