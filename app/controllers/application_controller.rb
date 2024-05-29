class ApplicationController < ActionController::Base
  include Pundit::Authorization
  include TwoFactorAuthenticationHelper

  before_action :handle_two_factor_authentication
  after_action :verify_authorized, unless: :devise_controller?

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  def current_resource_owner
    @_current_resource_owner ||= User.find(doorkeeper_token.resource_owner_id) if doorkeeper_token
  end

  def application_making_request
    @_application_making_request ||= OauthApplication.find(doorkeeper_token.application_id) if doorkeeper_token
  end  

private

  def redirect_to_prior_flow(args = {})
    redirect_to stored_location_for(:user) || :root, args
  end

  def user_not_authorized(_exception)
    flash[:alert] = "You do not have permission to perform this action."
    redirect_to root_path
  end

  def doorkeeper_authorize!
    original_return_value = super
    return original_return_value if user_via_token_has_signin_permission_on_app?

    # The following code is a distillation of the error path of
    # doorkeeper_authorize! from Doorkeeper::Rails::Helpers which is the
    # super version called above.
    options = doorkeeper_unauthorized_render_options
    status = :unauthorized
    if options.blank?
      head status
    else
      options[:status] = status
      options[:layout] = false if options[:layout].nil?
      render options
    end
    original_return_value
  end  

  def user_via_token_has_signin_permission_on_app?
    current_resource_owner && application_making_request && current_resource_owner.has_access_to?(application_making_request)
  end  
end
