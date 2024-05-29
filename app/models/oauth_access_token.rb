class OauthAccessToken < ApplicationRecord
  include ::Doorkeeper::Orm::ActiveRecord::Mixins::AccessToken

  # scopes
  scope :not_revoked, -> { where(revoked_at: nil) }
end
