require "rails_helper"

RSpec.describe "Authorise application", type: :feature do
  let(:application) { create(:oauth_application) }
  let(:user) { create(:user) }
  let(:auth_url) { "/oauth/authorize?response_type=code&client_id=#{application.uid}&redirect_uri=#{application.redirect_uri}" }

  scenario "user has 2FA mandated but has not set up 2FA" do
    when_i_visit_the_authorization_url
    then_i_am_redirected_to_sign_in_page
    and_i_sign_in
    then_i_am_redirected_to_the_2fa_setup_prompt_page
    and_access_is_not_granted_to_the_application
  end

  context "when user has 2FA set up" do
    let(:user) { create(:two_factor_enabled_user) }

    scenario "user has not passed 2FA" do
      when_i_visit_the_authorization_url
      then_i_am_redirected_to_sign_in_page
      and_i_sign_in
      then_i_am_prompted_for_a_2fa_code
      and_access_is_not_granted_to_the_application
    end

    scenario "user does not have 'signin' permission for application" do
      when_i_visit_the_authorization_url
      then_i_am_redirected_to_sign_in_page
      and_i_sign_in
      then_i_am_prompted_for_a_2fa_code
      and_i_enter_a_valid_2fa_code
      then_i_am_shown_an_unauthorised_message
      and_access_is_not_granted_to_the_application
    end

    scenario "user has 'signin' permission for application" do
      given_a_user_has_signin_permission_for_the_application
      when_i_visit_the_authorization_url
      then_i_am_redirected_to_sign_in_page
      and_i_sign_in
      then_i_am_prompted_for_a_2fa_code
      and_i_enter_a_valid_2fa_code
      then_i_am_redirected_to_the_application
      and_access_is_granted_to_the_application
    end
  end

private

  def when_i_visit_the_authorization_url
    visit auth_url
  end

  def then_i_am_redirected_to_sign_in_page
    expect(page).to have_text("Sign in to Publishing Platform")
  end

  def and_i_sign_in
    signin_with(user, set_up_2fa: false)
    expect(page).to have_text("Signed in successfully")
  end

  def then_i_am_redirected_to_the_2fa_setup_prompt_page
    expect(page).to have_text("Make your account more secure")
  end

  def and_access_is_granted_to_the_application
    expect(access_grant_for(user, application)).not_to be_nil, "Expected #{user.email} (ID #{user.id}) to have been granted access to #{application.name} (ID #{application.id}) but no matching AccessGrant found."
  end

  def and_access_is_not_granted_to_the_application
    expect(access_grant_for(user, application)).to be_nil, "Expected #{user.email} (ID #{user.id}) not to have been granted access to #{application.name} (ID #{application.id}) but a matching AccessGrant was found."
  end

  def then_i_am_prompted_for_a_2fa_code
    expect(page).to have_text("Use the app on your phone to get your 6-digit 2FA code")
  end

  def and_i_enter_a_valid_2fa_code
    complete_2fa_step(user)
  end

  def then_i_am_shown_an_unauthorised_message
    expect(page).to have_text("You don’t have permission to sign in to #{application.name}.")
  end

  def given_a_user_has_signin_permission_for_the_application
    user.grant_application_signin_permission(application)
  end

  def then_i_am_redirected_to_the_application
    expect(page).to have_current_path(/^#{application.redirect_uri}/, url: true)
    expect(page).to have_current_path(/\?code=/, url: true)
  end

  def access_grant_for(user, app)
    Doorkeeper::AccessGrant.find_by(resource_owner_id: user, application: app)
  end
end
