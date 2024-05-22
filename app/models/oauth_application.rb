require "doorkeeper/orm/active_record/mixins/application"

class OauthApplication < ApplicationRecord
  include ::Doorkeeper::Orm::ActiveRecord::Mixins::Application

  # associations
  has_many :permissions

  # hooks
  after_create :create_signin_permission

  def signin_permission
    permissions.signin.first
  end

private

  def create_signin_permission
    permissions.signin.create!
  end
end
