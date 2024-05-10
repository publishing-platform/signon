class UserParameterSanitiser
  def initialize(user_params, current_user_role)
    @user_params = user_params
    @current_user_role = current_user_role
  end

  def sanitise
    sanitised_params
  end

private

  def sanitised_params
    ActionController::Parameters.new(@user_params).permit(*permitted_params).to_h
  end

  def permitted_params
    permitted_params_by_role.fetch(@current_user_role, [])
  end

  def permitted_params_by_role
    {
      normal: Roles::Normal.permitted_user_params,
      admin: Roles::Admin.permitted_user_params,
    }
  end
end
