class ApiUsersController < ApplicationController
  before_action :authenticate_user!
  before_action :load_and_authorize_api_user, only: %i[edit update manage_tokens]

  def index
    authorize ApiUser
    # @api_users = ApiUser.includes(application_permissions: :application)
    @api_users = ApiUser
    @filter_params = filter_params
    filter_api_users
    order_api_users
    paginate_api_users
  end

  def new
    authorize ApiUser
    @api_user = ApiUser.new
  end

  def edit; end

  def update
    if Services::UserUpdater.call(@api_user, sanitised_api_user_params, current_user)
      redirect_to api_users_path, notice: "Updated user #{@api_user.email} successfully"
    else
      render :edit
    end  
  end

  def manage_tokens; end

  def create
    authorize ApiUser

    @api_user = ApiUser.build(sanitised_api_user_params)

    if @api_user.save
      redirect_to edit_api_user_path(@api_user), notice: "Successfully created API user"
    else
      render :new
    end
  end

private

  def load_and_authorize_api_user
    @api_user = ApiUser.find(params[:id])
    authorize @api_user
  end

  def permitted_api_user_params
    params.require(:api_user).permit(:name, :email).to_h
  end  

  def sanitised_api_user_params
    UserParameterSanitiser.new(
      permitted_api_user_params,
      current_user.role.to_sym,
    ).sanitise    
  end

  # def api_user_applications_and_permissions(user)
  #   zip_permissions(visible_applications(user), user)
  # end

  def filter_api_users
    @api_users = @api_users.filter_by_name(@filter_params[:name]) if @filter_params[:name].present?
  end

  def order_api_users
    @api_users = @api_users.order(:name)
  end

  def paginate_api_users
    page = params.fetch(:page, 1).to_i
    @api_users = @api_users.page(page).per(10)
  end    

  def filter_params
    params.permit(:name)
  end  
end