class Users::PermissionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user
  before_action :set_application
  before_action :set_permissions, only: %i[edit update]

  def edit
    authorize @user, :edit?

    @shared_permissions_form_locals = {
      action: user_application_permissions_path(@user, @application),
      application: @application,
      cancel_path: user_applications_path(@user),
      user: @user,
      permissions: @permissions,
    }
  end

  def update
    authorize @user, :edit?

    permission_ids = UserUpdatePermissionBuilder.new(
      user: @user,
      updatable_permission_ids: @permissions.pluck(:id),
      selected_permission_ids: update_params[:permission_ids].map(&:to_i),
    ).build

    Services::UserUpdater.call(@user, { permission_ids: }, current_user)

    flash[:notice] = "Permissions successfully updated"
    redirect_to user_applications_path(@user)
  end

private

  def update_params
    params.require(:application).permit(permission_ids: [])
  end

  def set_user
    @user = User.find(params[:user_id])
  end

  def set_application
    @application = OauthApplication.with_signin_permission_for(@user).not_api_only.find(params[:application_id])
  end

  def set_permissions
    @permissions = @application.sorted_permissions(include_signin: false)
  end
end