class UsersController < ApplicationController
  before_action :authenticate_user!, except: :show

  def show; end

  def index
    authorize User
    @users = policy_scope(User)
    @filter_params = filter_params
    filter_users
    order_users
    paginate_users
  end

private

  def filter_users
    @users = @users.filter_by_name(@filter_params[:name]) if @filter_params[:name].present?
    @users = @users.with_role(@filter_params[:role]) if @filter_params[:role].present?
    @users = @users.with_status(@filter_params[:status]) if @filter_params[:status].present?
    @users = @users.with_organisation(@filter_params[:organisation]) if @filter_params[:organisation].present?
  end

  def order_users
    @users = @users.order(:name)
  end

  def paginate_users
    page = params.fetch(:page, 1).to_i
    @users = @users.page(page).per(10)
  end  

  def filter_params
    params.permit(:name, :role, :status, :organisation)
  end

end