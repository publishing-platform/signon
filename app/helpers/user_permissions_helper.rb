module UserPermissionsHelper
  def applications_and_permissions(user)
    if policy(User).grant_permissions?
      OauthApplication.includes(:permissions)
    else
      OauthApplication.none
    end
  end

  def assigned_applications_and_permissions_for(user)
    user.permissions.includes(:oauth_application).group_by(&:oauth_application)
  end
end
