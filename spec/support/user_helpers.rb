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
      code = second_step == true ? ROTP::TOTP.new(user.otp_secret).now : second_step
      Timecop.freeze do
        fill_in :code, with: code
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
    end
  end

  # usage: accept_invitation(password: "<new password>", invitation_token: "<token>")
  def accept_invitation(options)
    raise "Please provide password" unless options[:password]
    raise "Please provide invitation token" unless options[:invitation_token]

    signout
    visit accept_user_invitation_path(invitation_token: options[:invitation_token])
    fill_in "New password", with: options[:password]
    fill_in "Confirm new password", with: options[:password]
    click_button "Save password"
  end
end
