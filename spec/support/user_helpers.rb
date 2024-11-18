module UserHelpers
  def signin_with(user = nil, email: nil, password: nil, second_step: true, set_up_2fa: true)
    user ||= User.find_by(email:)
    email ||= user.email
    password ||= user.password

    if user && user.require_2fa? && user.otp_secret.blank? && set_up_2fa
      user.update!(otp_secret: ROTP::Base32.random_base32)
    end

    fill_in "Email", with: email
    fill_in "Password", with: password
    click_button "Sign in"

    if second_step && user && user.otp_secret
      Timecop.freeze do
        fill_in :code, with: ROTP::TOTP.new(user.otp_secret).now
        click_button "Sign in"
      end
    end
  end

  def signout
    visit destroy_user_session_path
  end

  def enter_2fa_code(secret)
    Timecop.freeze do
      fill_in "code", with: ROTP::TOTP.new(secret).now
      find('button[type="submit"]').click
    end
  end
end
