module UsersHelper
  def organisation_options(form_builder)
    accessible_organisations = policy_scope(Organisation)
    options_from_collection_for_select(
      accessible_organisations,
      :id,
      :name,
      selected: form_builder.object.organisation_id,
    )
  end

  def organisation_select_options
    { include_blank: "" }
  end
end
