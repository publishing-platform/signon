module UserFilterHelper
  def filtered_user_roles
    current_user.manageable_roles
  end

  def filtered_organisations
    Organisation.order(:name).map { |org| [org.name, org.id] }
  end
end
