# frozen_string_literal: true

class Users::TwoFactorAuthenticationController < ApplicationController
  before_action :authenticate_user!
  skip_after_action :verify_authorized

  def prompt; end

  def show
    @otp_secret = ROTP::Base32.random_base32
  end

  def update
    mode = current_user.has_2fa? ? :change : :setup
    if verify_code_and_update
      redirect_to_prior_flow notice: t("two_factor_authentication.messages.success.#{mode}")
    else
      flash.now[:invalid_code] = t("two_factor_authentication_session.attempt_failed")
      render :show, status: :unprocessable_entity
    end
  end

private

  def otp_secret_uri
    issuer = "DEVGOV.UK Signon"
    if Rails.application.config.instance_name
      issuer = "#{Rails.application.config.instance_name.titleize} #{issuer}"
    end

    issuer = ERB::Util.url_encode(issuer)
    "otpauth://totp/#{issuer}:#{current_user.email}?secret=#{@otp_secret.upcase}&issuer=#{issuer}"
  end

  def qr_code_data_uri
    qr_code = RQRCode::QRCode.new(otp_secret_uri, level: :m)
    qr_code.as_png(size: 180, fill: ChunkyPNG::Color::TRANSPARENT).to_data_url
  end
  helper_method :qr_code_data_uri

  def verify_code_and_update
    @otp_secret = params[:otp_secret]
    totp = ROTP::TOTP.new(@otp_secret)
    if totp.verify(params[:code], drift_behind: User::MAX_2FA_DRIFT_SECONDS)
      current_user.update!(otp_secret: @otp_secret)
      true
    else
      false
    end
  end
end
