class UserMailer < Devise::Mailer
  include MailerHelper

  default from: proc { email_from }

  helper_method :account_name, :app_name, :instance_name, :locked_time, :unlock_time

  def two_factor_reset(user)
    @user = user
    mail(to: @user.email, subject: "2-Factor Authentication (2FA) has been reset")
  end

  def confirmation_instructions(user, token, _opts = {})
    @user = user
    @token = token
    mail(to: @user.unconfirmed_email, subject: t("devise.mailer.confirmation_instructions.subject"))
  end

  def reset_password_instructions(user, token, _opts = {})
    @user = user
    @token = token
    mail(to: @user.email, subject: t("devise.mailer.reset_password_instructions.subject"))
  end

  def unlock_instructions(user, _token, _opts = {})
    @user = user
    mail(to: @user.email, subject: sprintf(t("devise.mailer.unlock_instructions.subject"), app_name:))
  end

  def email_changed(user, _opts = {})
    @user = user
    mail(to: @user.email, subject: t("devise.mailer.email_changed.subject"))
  end

  def email_changed_notification(user)
    @user = user
    mail(to: @user.email, subject: "Your #{app_name} email address is being changed")
  end

  def password_change(user, _opts = {})
    @user = user
    mail(to: @user.email, subject: t("devise.mailer.password_change.subject"))
  end

  def invitation_instructions(user, token, _opts = {})
    @user = user
    @token = token
    mail(to: @user.email, subject: t("devise.mailer.invitation_instructions.subject"))
  end

private

  def account_name
    if instance_name.present?
      "#{instance_name} account"
    else
      "account"
    end
  end

  def locked_time
    @user.locked_at.to_fs(:publishing_platform_date)
  end

  def unlock_time
    (@user.locked_at + 1.hour).to_fs(:publishing_platform_date)
  end
end
