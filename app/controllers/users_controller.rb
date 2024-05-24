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

  def edit
    @user = User.find(params[:id])
    authorize @user
  end

  def update
    @user = User.find(params[:id])
    authorize @user

    if Services::UserUpdater.call(@user, sanitised_user_params, current_user)
      redirect_to users_path, notice: "Updated user #{@user.email} successfully"
    else
      render :edit
    end
  end

  def edit_email_or_password
    @user = User.find(params[:id])
    authorize @user
  end

  def update_email
    @user = User.find(params[:id])
    authorize @user
    new_email = params[:user][:email]

    if @user.email == new_email.strip
      flash[:alert] = "Nothing to update."
      render :edit_email_or_password
    elsif @user.update(email: new_email)
      UserMailer.email_changed_notification(@user).deliver_later
      redirect_to root_path, notice: "An email has been sent to #{new_email}. Follow the link in the email to update your address."
    else
      render :edit_email_or_password
    end
  end

  def update_password
    @user = User.find(params[:id])
    authorize @user

    if @user.update_with_password(password_params)
      flash[:notice] = t(:updated, scope: "devise.passwords")
      bypass_sign_in(@user)
      redirect_to root_path
    else
      render :edit_email_or_password
    end
  end

  def resend_email_change
    @user = User.find(params[:id])
    authorize @user

    if @user.pending_reconfirmation?
      @user.send_confirmation_instructions

      if @user.errors.empty?
        notice = if current_user.normal?
                   "An email has been sent to #{@user.unconfirmed_email}. Follow the link in the email to update your address."
                 else
                   "Successfully resent email change email to #{@user.unconfirmed_email}"
                 end
        redirect_to root_path, notice:
      else
        redirect_to edit_user_path(@user), alert: "Failed to send email change email"
      end
    else
      redirect_to edit_user_path(@user), alert: "Failed to send email change email"
    end
  end

  def cancel_email_change
    @user = User.find(params[:id])
    authorize @user

    if @user.pending_reconfirmation?
      @user.unconfirmed_email = nil
      @user.confirmation_token = nil
      @user.save!(validate: false)
    end

    redirect_back_or_to(root_path)
  end

  def reset_2fa
    @user = User.find(params[:id])
    authorize @user

    @user.reset_2fa!
    UserMailer.two_factor_reset(@user).deliver_later

    redirect_back_or_to root_path, notice: "Reset 2-Factor Authentication (2FA) for #{@user.email}"
  end

  def unlock
    @user = User.find(params[:id])
    authorize @user

    @user.unlock_access!
    redirect_back_or_to root_path, notice: "Unlocked #{@user.email}"
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

  def permitted_user_params
    params.require(:user).permit(
      :name,
      :email,
      :organisation_id,
      :role,
      permission_ids: [],
    ).to_h
  end

  def sanitised_user_params
    UserParameterSanitiser.new(
      permitted_user_params,
      current_user_role,
    ).sanitise
  end

  def password_params
    params.require(:user).permit(
      :current_password,
      :password,
      :password_confirmation,
    )
  end

  def current_user_role
    current_user.role.to_sym
  end
end
