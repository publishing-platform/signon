module RootHelper
  def signin_required_title(application)
    if application.blank?
      "You don’t have permission to use this app."
    else
      "You don’t have permission to sign in to #{application.name}."
    end
  end
end
