class UserPolicy < BasePolicy
  def index?
    current_user.admin?
  end

  alias_method :new?, :index?
  alias_method :edit?, :index?
  alias_method :create?, :index?
  alias_method :update?, :index?
  alias_method :assign_organisations?, :index?
  alias_method :grant_permissions?, :index?
  alias_method :edit_suspension?, :index?
  alias_method :update_suspension?, :index?
  alias_method :unlock?, :index?
  alias_method :resend?, :index?

  def edit_email_or_password?
    allow_self_only
  end

  alias_method :update_email?, :edit_email_or_password?
  alias_method :update_password?, :edit_email_or_password?

  def cancel_email_change?
    allow_self_only || edit?
  end

  def resend_email_change?
    allow_self_only || edit?
  end

  def assign_role?
    current_user.admin?
  end

private

  def allow_self_only
    current_user.id == record.id
  end

  class Scope < BasePolicy::Scope
    def resolve
      if current_user.admin?
        scope.web_users
      else
        scope.none
      end
    end
  end
end
