class Users::SigninPermissionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user
  before_action :set_application, except: [:create]

  def create
    application = OauthApplication.not_api_only.find(params[:application_id])
    authorize @user, :edit?

    params = { permission_ids: @user.permissions.map(&:id) + [application.signin_permission.id] }
    Services::UserUpdater.call(@user, params, current_user)

    redirect_to user_applications_path(@user)
  end

  def delete
    authorize @user, :edit?
  end

  def destroy
    authorize @user, :edit?

    params = { permission_ids: @user.permissions.map(&:id) - [@application.signin_permission.id] }
    Services::UserUpdater.call(@user, params, current_user)

    redirect_to user_applications_path(@user)
  end

private

  def set_user
    @user = User.find(params[:user_id])
  end

  def set_application
    @application = OauthApplication.with_signin_permission_for(@user).not_api_only.find(params[:application_id])
  end
end