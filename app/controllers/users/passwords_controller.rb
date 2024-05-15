# frozen_string_literal: true

class Users::PasswordsController < Devise::PasswordsController
  # GET /resource/password/new
  # def new
  #   super
  # end

  # POST /resource/password
  # def create
  #   super
  # end

  # GET /resource/password/edit?reset_password_token=abcdef
  # def edit
  #   super
  # end

  # PUT /resource/password
  # def update
  #   super
  # end

  # protected

  # def after_resetting_password_path_for(resource)
  #   super(resource)
  # end

  # The path used after sending reset password instructions
  # def after_sending_reset_password_instructions_path_for(resource_name)
  #   super(resource_name)
  # end

  def edit
    super

    user = user_from_params
    unless user && user.reset_password_period_valid?
      render "users/passwords/reset_error"
    end
  end  

private

  def user_from_params
    token = Devise.token_generator.digest(self, :reset_password_token, params[:reset_password_token])
    User.find_by(reset_password_token: token)
  end

end
