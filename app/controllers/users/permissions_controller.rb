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
    # authorize UserApplicationPermission.for(@user, @application)

    # selected_permission_ids = []

    # if update_params[:supported_permission_ids]
    #   selected_permission_ids = update_params[:supported_permission_ids]
    # elsif update_params[:new_permission_id]&.length&.> 0
    #   selected_permission_ids.concat(update_params[:current_permission_ids] || [], [update_params[:new_permission_id]])
    # else
    #   flash[:alert] = "You must select a permission."
    #   redirect_to edit_user_application_permissions_path(@user, @application)
    #   return
    # end

    # supported_permission_ids = UserUpdatePermissionBuilder.new(
    #   user: @user,
    #   updatable_permission_ids: @permissions.pluck(:id),
    #   selected_permission_ids: selected_permission_ids.map(&:to_i),
    # ).build

    # UserUpdate.new(@user, { supported_permission_ids: }, current_user, user_ip_address).call

    # flash[:application_id] = @application.id
    # redirect_to user_applications_path(@user)
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