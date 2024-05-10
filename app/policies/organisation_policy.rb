class OrganisationPolicy < BasePolicy
  def index?
    current_user.admin?
  end

  alias_method :edit?, :index?

  class Scope < ::BasePolicy::Scope
    def resolve
      if current_user.admin?
        scope.all
      else
        scope.none
      end
    end
  end
end
