module Devise::Hooks::TwoFactorAuthentication
  Warden::Manager.after_authentication do |user, auth, _opts|
    if user.has_2fa?
      cookie = auth.env["action_dispatch.cookies"].signed["2fa_session"]

      valid = cookie &&
        cookie["user_id"] = user.id &&
          cookie["valid_until"] > Time.zone.now &&
          cookie["otp_secret_hash"] == Digest::SHA256.hexdigest(user.otp_secret)

      unless valid
        auth.session(:user)["need_two_factor_authentication"] = true
      end
    end
  end
end
