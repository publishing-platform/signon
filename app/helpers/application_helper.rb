# frozen_string_literal: true

module ApplicationHelper
  def navigation_items
    return [] unless current_user

    items = []

    items << { text: "Dashboard", href: root_path, active: is_current?(root_path) }

    if policy(User).index?
      items << { text: "Users", href: users_path, active: is_current?(users_path) }
    end

    if policy(ApiUser).index?
      items << { text: "APIs", href: api_users_path, active: is_current?(api_users_path) }
    end

    if policy(OauthApplication).index?
      items << { text: "Apps", href: oauth_applications_path, active: is_current?(oauth_applications_path) }
    end

    items << { text: current_user.name, href: edit_email_or_password_user_path(current_user) }
    items << { text: "Sign out", href: destroy_user_session_path }
  end

  def is_current?(link)
    recognized = Rails.application.routes.recognize_path(link)
    recognized[:controller] == params[:controller] &&
      recognized[:action] == params[:action]
  end
end
