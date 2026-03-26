require "rails_helper"

RSpec.describe "Manage API user", type: :feature do
  let(:user) { create(:admin_user) }
  let!(:application) { create(:oauth_application, name: "app-name", with_permissions: ["Managing Editor"]) }
  let(:api_user) { create(:api_user) }

  scenario "create and edit an API user" do
    given_a_signed_in_user
    when_i_navigate_to_the_create_api_user_page
    and_i_submit_the_create_form
    then_i_am_redirected_to_the_edit_api_user_page
    and_i_see_a_success_message
    when_i_make_changes_and_submit_the_edit_form
    then_i_am_redirected_to_the_index_page
    and_i_see_that_the_api_user_was_successfully_updated
  end

  scenario "granting and revoking application access" do
    given_a_signed_in_user
    when_i_navigate_to_the_manage_tokens_page
    and_i_create_an_application_access_token
    then_i_see_that_the_token_was_succesfully_created
    and_the_api_user_has_application_signin_permission
    when_i_revoke_the_access_token
    then_i_see_that_the_token_was_successfully_revoked
  end

  context "when an api user has signin access to an application" do
    let(:api_user) { create(:api_user, with_signin_permissions_for: [application]) }

    before do
      create(:oauth_access_token, application:, resource_owner_id: api_user.id)
    end

    scenario "granting additional permissions" do
      given_a_signed_in_user
      when_i_navigate_to_the_api_user_applications_page
      then_i_see_the_application_listed
      when_i_click_update_permissions_for_application
      and_i_check_an_additional_permission
      and_i_view_permissions_for_application
      then_i_see_the_additional_permission_has_been_granted
      and_the_api_user_has_application_signin_permission
    end

    context "and an api user has been granted an additional permission" do
      let(:api_user) do
        create(:api_user,
               with_signin_permissions_for: [application],
               with_permissions: { application => ["Managing Editor"] })
      end

      scenario "revoking additional permissions" do
        given_a_signed_in_user
        when_i_navigate_to_the_api_user_applications_page
        then_i_see_the_application_listed
        when_i_click_update_permissions_for_application
        and_i_uncheck_the_additional_permission
        and_i_view_permissions_for_application
        then_i_see_the_additional_permission_has_been_revoked
        and_the_api_user_has_application_signin_permission
      end
    end
  end

private

  def given_a_signed_in_user
    visit new_user_session_path
    expect(page).to have_text("Sign in to Publishing Platform")

    signin_with(user)
    expect(page).to have_text("Signed in successfully")

    complete_2fa_step(user)

    expect(page).to have_text("Your applications")
    expect(page).to have_current_path(root_path)
  end

  def when_i_navigate_to_the_create_api_user_page
    click_link "APIs"
    expect(page).to have_text("API users")

    click_link "Create API user"
    expect(page).to have_selector("form.new_api_user")
  end

  def and_i_submit_the_create_form
    fill_in "Name", with: "Content Store Application"
    fill_in "Email", with: "content.store@publishing-platform.co.uk"
    click_button "Create API user"
  end

  def then_i_am_redirected_to_the_edit_api_user_page
    expect(page).to have_text("Edit Content Store Application")
  end

  def and_i_see_a_success_message
    expect(page).to have_text("Successfully created API user")
  end

  def when_i_make_changes_and_submit_the_edit_form
    fill_in "Name", with: "Collections Application"
    fill_in "Email", with: "collections@publishing-platform.co.uk"

    click_button "Save API user"
  end

  def then_i_am_redirected_to_the_index_page
    expect(page).to have_text("API users")
  end

  def and_i_see_that_the_api_user_was_successfully_updated
    expect(page).to have_text("Updated user collections@publishing-platform.co.uk successfully")
    expect(page).to have_selector("table tr td:nth-child(1)", text: /collections@publishing-platform.co.uk/)
  end

  def when_i_navigate_to_the_manage_tokens_page
    visit manage_tokens_api_user_path(api_user)
    expect(page).to have_text("Manage tokens for #{api_user.name}")
  end

  def and_i_create_an_application_access_token
    click_link "Add application token"
    expect(page).to have_text("Create new access token for #{api_user.name}")

    select application.name, from: "authorisation_application_id"

    click_button "Create access token"
  end

  def then_i_see_that_the_token_was_succesfully_created
    # run capybara's waiting mechanism to ensure the page has loaded before attemping to access the user's token, this ensures the server side functionality
    # of creating the token and associating it with the user has completed before we attempt to access it
    # https://github.com/teamcapybara/capybara/issues/2800
    expect(page).to have_selector("div[role='alert']", text: "Make sure to copy the access token for #{application.name} now. You won't be able to see it again!")
    expect(page).to have_selector("div[role='alert'] label", text: "Access token for #{application.name}")

    token = api_user.authorisations.last.token

    expect(page).to have_selector("div[role='alert'] input[value='#{token}']")

    # shows truncated token
    expect(page).to have_selector("table tr td:nth-child(2)", text: /^#{token[0..7]}/)
  end

  def when_i_navigate_to_the_api_user_applications_page
    visit api_user_applications_path(api_user)
  end

  def then_i_see_the_application_listed
    expect(page).to have_selector("table tr td:nth-child(1)", text: application.name)
  end

  def when_i_click_update_permissions_for_application
    click_link "Update permissions for #{application.name}"
    expect(page).to have_text("Update #{api_user.name}'s permissions for #{application.name}")
  end

  def and_i_check_an_additional_permission
    check "Managing Editor"
    click_button "Update permissions"
  end

  def and_i_uncheck_the_additional_permission
    uncheck "Managing Editor"
    click_button "Update permissions"
  end

  def and_i_view_permissions_for_application
    click_link "Update permissions for #{application.name}"
    expect(page).to have_text("Update #{api_user.name}'s permissions for #{application.name}")
  end

  def then_i_see_the_additional_permission_has_been_granted
    expect(page).to have_checked_field("Managing Editor")
  end

  def then_i_see_the_additional_permission_has_been_revoked
    expect(page).not_to have_checked_field("Managing Editor")
  end

  def when_i_revoke_the_access_token
    text = "Revoke token giving #{api_user.name} access to #{application.name}"
    click_link text
    expect(page).to have_text(text)

    click_button "Revoke token"
  end

  def then_i_see_that_the_token_was_successfully_revoked
    expect(page).to have_text("Access for #{application.name} was revoked")
    expect(page).not_to have_selector("table tr td:nth-child(1)", text: application.name)
  end

  def and_the_api_user_has_application_signin_permission
    expect(api_user.has_access_to?(application)).to be true
  end
end
