# frozen_string_literal: true

module ApplicationTableHelper
  def update_permissions_link(user, application)
    link_path = if user.api_user?
                  edit_api_user_application_permissions_path(user, application)
                else
                  edit_user_application_permissions_path(user, application)
                end

    if application.sorted_permissions(include_signin: false).any?
      link_to(link_path, class: "me-3") do
        safe_join(
          ["Update permissions",
           content_tag(:span, " for #{application.name}", class: "visually-hidden")],           
        )
      end
    else
      ""
    end
  end 
end