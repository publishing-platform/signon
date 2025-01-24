# frozen_string_literal: true

class Users::TwoFactorAuthenticationSessionController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_user_has_2fa_setup
  skip_before_action :handle_two_factor_authentication
  skip_after_action :verify_authorized

  def new; end

  def create
    if current_user.authenticate_otp(params[:code])
      session_expires = User::REMEMBER_2FA_SESSION_FOR.from_now
      cookies.signed["2fa_session"] = {
        value: {
          user_id: current_user.id,
          valid_until: session_expires,
          otp_secret_hash: Digest::SHA256.hexdigest(current_user.otp_secret),
        },
        secure: Rails.env.production?,
        httponly: true,
        expires: session_expires,
      }

      warden.session(:user)["need_two_factor_authentication"] = false
      redirect_to_prior_flow
    else
      flash.now["alert"] = t("two_factor_authentication_session.attempt_failed")
      render(:new)
    end
  end

private

  def ensure_user_has_2fa_setup
    redirect_to root_path unless current_user.has_2fa?
  end
end
