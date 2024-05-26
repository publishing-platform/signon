class ApiUser < User
  # validation
  validate :require_2fa_is_false
  # scopes
  default_scope { where(api_user: true).order(:name) }

  DEFAULT_TOKEN_LIFE = 2.years.to_i

  def self.build(attributes = {})
    password = SecureRandom.urlsafe_base64
    new(attributes.merge(password:, password_confirmation: password)).tap do |u|
      u.skip_confirmation!
      u.require_2fa = false
      u.api_user = true
    end
  end  

private
  
  def require_2fa_is_false
    errors.add(:require_2fa, "can't be true for api user") if require_2fa
  end
end
