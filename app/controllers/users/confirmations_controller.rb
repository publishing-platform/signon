# frozen_string_literal: true

class Users::ConfirmationsController < Devise::ConfirmationsController
  # GET /resource/confirmation/new
  def new
    handle_new_token_needed
  end

  # POST /resource/confirmation
  def create
    handle_new_token_needed
  end

  # GET /resource/confirmation?confirmation_token=abcdef
  def show
    if user_signed_in?
      if confirmation_user.persisted? && current_user.email != confirmation_user.email
        redirect_to root_path, alert: "It appears you followed a link meant for another user."
      else
        self.resource = resource_class.confirm_by_token(params[:confirmation_token])

        if resource.errors.empty?
          set_flash_message(:notice, :confirmed) if is_navigational_format?
          sign_in(resource_name, resource)
          respond_with_navigational(resource) { redirect_to after_confirmation_path_for(resource_name, resource) }
        else
          respond_with_navigational(resource.errors, status: :unprocessable_entity) { handle_new_token_needed }
        end
      end
    else
      self.resource = confirmation_user
      unless resource.persisted?
        respond_with_navigational(resource.errors, status: :unprocessable_entity) { handle_new_token_needed }
      end
    end
  end

  def update
    self.resource = confirmation_user

    if resource.valid_password?(params[:user][:password])
      self.resource = resource_class.confirm_by_token(params[:confirmation_token])
      if resource.errors.empty?
        set_flash_message(:notice, :confirmed) if is_navigational_format?
        sign_in(resource_name, resource)
        respond_with_navigational(resource) { redirect_to after_confirmation_path_for(resource_name, resource) }
      else
        respond_with_navigational(resource.errors, status: :unprocessable_entity) { handle_new_token_needed }
      end
    else
      flash.now[:alert] = "Password was incorrect"
      render :show
    end
  end

# protected

# The path used after resending confirmation instructions.
# def after_resending_confirmation_instructions_path_for(resource_name)
#   super(resource_name)
# end

# The path used after confirmation.
# def after_confirmation_path_for(resource_name, resource)
#   super(resource_name, resource)
# end
private

  def confirmation_user
    @confirmation_user ||= resource_class.find_or_initialize_by(confirmation_token: params[:confirmation_token])
  end

  def handle_new_token_needed
    path = user_signed_in? ? root_path : new_user_session_path
    redirect_to path, alert: "Couldn't confirm email change. Please contact support to request a new confirmation email."
  end
end
