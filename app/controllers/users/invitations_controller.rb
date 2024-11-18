class Users::InvitationsController < Devise::InvitationsController
  before_action :authenticate_inviter!, only: %i[new create resend]
  after_action :verify_authorized, except: %i[edit update] # rubocop:disable Rails/LexicallyScopedActionFilter

  def new
    authorize User
    super
  end

  def create
    if (self.resource = User.find_by(email: params[:user][:email]))
      authorize resource
      flash[:alert] = "User already invited. If you want to, you can click 'Resend signup email'."
      respond_with resource, location: users_path
    else
      user = User.new(sanitised_user_params)
      authorize user

      self.resource = resource_class.invite!(sanitised_user_params, current_inviter)
      if resource.errors.empty?
        set_flash_message :notice, :send_instructions, email: resource.email
        respond_with resource, location: after_invite_path_for(resource)
      else
        respond_with_navigational(resource) { render :new }
      end
    end
  end

  def resend
    user = User.find(params[:id])
    authorize user

    user.invite!
    flash[:notice] = "Resent account signup email to #{user.email}"
    redirect_to users_path
  end

private

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

  def current_user_role
    current_user.try(:role).try(:to_sym) || :normal
  end
end
