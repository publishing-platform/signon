module ApiUsersHelper
  def truncate_access_token(token)
    raw "#{token[0..7]}#{'&bull;' * 24}#{token[-8..]}"
  end

  def application_list(user)
    content_tag(:ul, class: "list-unstyled") do
      safe_join(
        authorised_applications(user).map do |application|
          next unless user.permission_ids_for(application).any?

          content_tag(:li, application.name)
        end,
      )
    end
  end

  def authorised_applications(user)
    applications = OauthApplication.includes(:permissions)
    authorised_apps = user.authorisations.where(revoked_at: nil).pluck(:application_id)
    applications.where(id: authorised_apps)
  end
end
