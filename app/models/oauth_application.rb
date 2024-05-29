require "doorkeeper/orm/active_record/mixins/application"

class OauthApplication < ApplicationRecord
  include ::Doorkeeper::Orm::ActiveRecord::Mixins::Application

  # associations
  has_many :permissions

  # hooks
  after_create :create_signin_permission

  # scopes
  default_scope { ordered_by_name }
  scope :ordered_by_name, -> { order("oauth_applications.name") }
  scope :api_only, -> { where(api_only: true) }
  scope :not_api_only, -> { where(api_only: false) }
  scope :can_signin, ->(user) { with_signin_permission_for(user) }
  scope :with_signin_permission_for,
        lambda { |user|
          joins(permissions: :users_permissions)
            .where(users_permissions: { user: })
            .merge(Permission.signin)
        }
  scope :without_signin_permission_for,
        lambda { |user|
          excluded_app_ids = with_signin_permission_for(user).map(&:id)
          where.not(id: excluded_app_ids)
        }

  def signin_permission
    permissions.signin.first
  end

  def sorted_permissions(include_signin: true)
    sorted_permissions = permissions.order(:name)
    sorted_permissions_without_signin = sorted_permissions - [signin_permission]

    if include_signin
      ([signin_permission] + sorted_permissions_without_signin).compact
    else
      sorted_permissions_without_signin
    end
  end

private

  def create_signin_permission
    permissions.signin.create!
  end
end
