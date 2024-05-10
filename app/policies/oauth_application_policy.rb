class OauthApplicationPolicy < BasePolicy
  def index?
    current_user.admin?
  end

  alias_method :new?, :index?
  alias_method :edit?, :index?
  alias_method :create?, :index?
  alias_method :update?, :index?
end
