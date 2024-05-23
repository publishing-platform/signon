class OauthApplicationsController < ApplicationController
  before_action :authenticate_user!

  respond_to :html

  def index
    authorize OauthApplication
    @applications = OauthApplication.all
  end

  def new
    authorize OauthApplication
    @application = OauthApplication.new
  end

  def edit
    @application = OauthApplication.find(params[:id])
    authorize @application
  end

  def create
    authorize OauthApplication
    @application = OauthApplication.new(permitted_application_params)

    if @application.save
      redirect_to oauth_applications_path, notice: "Successfully created #{@application.name}"
    else
      respond_with @application
    end
  end

  def update
    @application = OauthApplication.find(params[:id])
    authorize @application

    if @application.update(permitted_application_params)
      redirect_to oauth_applications_path, notice: "Successfully updated #{@application.name}"
    else
      respond_with @application
    end
  end

private

  def permitted_application_params
    params.require(:oauth_application).permit(
      :name,
      :description,
      :home_uri,
      :redirect_uri,
      :uid,
      :secret,
      :retired,
      :api_only,
    )
  end
end
