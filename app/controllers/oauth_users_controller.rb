class OauthUsersController < ApplicationController
  before_action :doorkeeper_authorize!
  before_action :validate_token_matches_client_id
  skip_after_action :verify_authorized

  def show
    respond_to do |format|
      format.json do
        presenter = UserOauthPresenter.new(current_resource_owner, application_making_request)
        render json: presenter.as_hash.to_json
      end
    end
  end

private

  def validate_token_matches_client_id
    if params[:client_id] != doorkeeper_token.application.uid
      head :unauthorized
    end
  end
end