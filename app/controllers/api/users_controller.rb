class Api::UsersController < ApplicationController
  before_action :doorkeeper_authorize!
  before_action :validate_token_for_signon
  skip_after_action :verify_authorized

  def index
    users = User.where(uid: params[:uuids])
    render json: Api::UserPresenter.present_many(users)
  end

private

  def validate_token_for_signon
    head :unauthorized unless doorkeeper_token&.application&.signon?
  end
end
