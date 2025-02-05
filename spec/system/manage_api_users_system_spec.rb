require "rails_helper"

RSpec.describe "Manage API users", type: :system do
  let(:user) { create(:admin_user) }
  let!(:application) { create(:oauth_application, name: "app-name", with_permissions: ["Managing Editor"]) }
  let(:api_user) { create(:api_user) }

  before do
    visit new_user_session_path
    signin_with(user)
  end

  it "allows API user to be created and edited" do
    click_link "APIs"
    click_link "Create API user"

    fill_in "Name", with: "Content Store Application"
    fill_in "Email", with: "content.store@publishing-platform.co.uk"
    click_button "Create API user"

    expect(page).to have_text("Successfully created API user")

    fill_in "Name", with: "Collections Application"
    fill_in "Email", with: "collections@publishing-platform.co.uk"

    click_button "Save API user"

    expect(page).to have_text("Updated user collections@publishing-platform.co.uk successfully")
    expect(page).to have_selector("table tr td:nth-child(1)", text: /collections@publishing-platform.co.uk/)
  end

  it "allows granting of application access and management of permissions" do
    visit manage_tokens_api_user_path(api_user)

    click_link "Add application token"

    select "app-name", from: "authorisation_application_id"

    click_button "Create access token"

    token = api_user.authorisations.last.token

    expect(page).to have_selector("div[role='alert']", text: "Make sure to copy the access token for app-name now. You won't be able to see it again!")
    expect(page).to have_selector("div[role='alert'] label", text: "Access token for #{application.name}")
    expect(page).to have_selector("div[role='alert'] input[value='#{token}']")

    # shows truncated token
    expect(page).to have_selector("table tr td:nth-child(2)", text: /^#{token[0..7]}/)

    click_link api_user.name
    click_link "Manage permissions"

    assert_user_has_signin_permission_for(api_user, application)
    assert_has_access_token_for(application.name)

    click_link "Update permissions for #{application.name}"
    check "Managing Editor"
    click_button "Update permissions"

    assert_has_other_permission(application.name, "Managing Editor")

    uncheck "Managing Editor"
    click_button "Update permissions"

    assert_does_not_have_other_permission(application.name, "Managing Editor")
  end

  it "allows revoking of application access" do
    visit manage_tokens_api_user_path(api_user)

    click_link "Add application token"

    select "app-name", from: "authorisation_application_id"

    click_button "Create access token"

    assert_has_access_token_for(application.name)

    click_link "Revoke"
    click_button "Revoke"

    expect(page).to have_text("Access for #{application.name} was revoked")
    assert_does_not_have_access_token_for(application.name)
  end

private

  def assert_user_has_signin_permission_for(user, application)
    expect(user.has_access_to?(application)).to be true
  end

  def assert_has_access_token_for(_application_name)
    expect(page).to have_selector("table tr td:nth-child(1)", text: application.name)
  end

  def assert_does_not_have_access_token_for(_application_name)
    expect(page).not_to have_selector("table tr td:nth-child(1)", text: application.name)
  end

  def assert_has_other_permission(application_name, permission_name)
    click_link "Update permissions for #{application_name}"
    expect(page).to have_checked_field(permission_name)
  end

  def assert_does_not_have_other_permission(application_name, permission_name)
    click_link "Update permissions for #{application_name}"
    expect(page).not_to have_checked_field(permission_name)
  end
end
