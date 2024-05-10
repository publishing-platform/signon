# frozen_string_literal: true

class BasePolicy
  attr_reader :current_user, :record

  def initialize(current_user, record)
    @current_user = current_user
    @record = record
  end

  class Scope
    def initialize(current_user, scope)
      @current_user = current_user
      @scope = scope
    end

    def resolve
      raise NotImplementedError, "You must define #resolve in #{self.class}"
    end

    attr_reader :current_user, :scope
  end
end
