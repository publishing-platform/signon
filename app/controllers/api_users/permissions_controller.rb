class ApiUsers::PermissionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user
  before_action :set_application
  before_action :set_permissions

  def edit
    authorize @api_user

    @shared_permissions_form_locals = {
      action: api_user_application_permissions_path(@api_user, @application),
      application: @application,
      cancel_path: api_user_applications_path(@api_user),
      user: @api_user,
      permissions: @permissions,
    }
  end

  def update
    authorize @api_user

    permission_ids = UserUpdatePermissionBuilder.new(
      user: @api_user,
      updatable_permission_ids: @permissions.pluck(:id),
      selected_permission_ids: update_params[:permission_ids].map(&:to_i),
    ).build

    Services::UserUpdater.call(@api_user, { permission_ids: }, current_user)

    flash[:notice] = "Permissions successfully updated"
    redirect_to api_user_applications_path(@api_user)
  end

private

  def update_params
    params.require(:application).permit(permission_ids: [])
  end

  def set_user
    @api_user = ApiUser.find(params[:api_user_id])
  end

  def set_application
    @application = @api_user.authorised_applications.merge(OauthAccessToken.not_revoked).find(params[:application_id])
  end

  def set_permissions
    @permissions = @application.sorted_permissions(include_signin: false)
  end
end
