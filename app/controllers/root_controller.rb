class RootController < ApplicationController
  before_action :authenticate_user!
  skip_after_action :verify_authorized

  def index
    @applications = OauthApplication.not_api_only.can_signin(current_user)
  end

  def signin_required
    @application = OauthApplication.find_by(id: session.delete(:signin_missing_for_application))
  end  
end
