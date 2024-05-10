module TwoFactorAuthenticationHelper
private

  def handle_two_factor_authentication
    return unless signed_in?(:user)

    if warden.session(:user)["need_two_factor_authentication"]
      redirect_to new_two_factor_authentication_session_path
    elsif current_user.prompt_for_2fa? && !on_2fa_setup_journey
      # NOTE: 'Prompt' means prompt the user to _set up_ 2FA.
      redirect_to prompt_two_factor_authentication_path
    end
  end

  def on_2fa_setup_journey
    controller_path == Users::TwoFactorAuthenticationController.controller_path
  end
end
