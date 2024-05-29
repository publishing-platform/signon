module ApiUsersHelper
  def truncate_access_token(token)
    raw "#{token[0..7]}#{'&bull;' * 24}#{token[-8..]}"
  end

  def application_list(user)
    content_tag(:ul, class: "list-unstyled") do
      safe_join(
        user.authorised_applications.merge(OauthAccessToken.not_revoked).includes(:permissions).map do |application|
          next unless user.permission_ids_for(application).any?

          content_tag(:li, application.name)
        end,
      )
    end
  end
end
