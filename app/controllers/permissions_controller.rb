class PermissionsController < ApplicationController
  before_action :authenticate_user!
  before_action :load_and_authorize_application

  respond_to :html

  def index; end

  def new
    @permission = @application.permissions.build
  end

  def edit
    @permission = Permission.find(params[:id])
  end

  def create
    @permission = @application.permissions.build(permitted_permission_params)

    if @permission.save
      redirect_to oauth_application_permissions_path,
                  notice: "Successfully added permission #{@permission.name} to #{@application.name}"
    else
      render :new
    end
  end

  def update
    @permission = Permission.find(params[:id])

    if @permission.update(permitted_permission_params)
      redirect_to oauth_application_permissions_path, notice: "Successfully updated permission #{@permission.name}"
    else
      render :edit
    end
  end

private

  def load_and_authorize_application
    @application = OauthApplication.find(params[:oauth_application_id])
    authorize @application
  end

  def permitted_permission_params
    params.require(:permission).permit(:name)
  end
end
