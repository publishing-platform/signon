class RootController < ApplicationController
  before_action :authenticate_user!
  skip_after_action :verify_authorized

  def index
    @applications = OauthApplication.not_api_only.can_signin(current_user)
  end
end
