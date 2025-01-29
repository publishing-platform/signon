require "rails_helper"

RSpec.describe "Authorise application", type: :system do
  let(:application) { create(:oauth_application) }
  let(:user) { create(:user) }

  context "when user is not authenticated" do
    it "redirects user to sign in" do
      visit "/oauth/authorize?response_type=code&client_id=#{application.uid}&redirect_uri=#{application.redirect_uri}"

      expect(page.body).to include("Sign in to Publishing Platform")
    end
  end

  context "when the user has had 2FA mandated" do
    before do
      user.update!(require_2fa: true)
      visit "/oauth/authorize?response_type=code&client_id=#{application.uid}&redirect_uri=#{application.redirect_uri}"
      signin_with(user, set_up_2fa: false)
    end

    it "does not authorise access to the application and redirects to 2FA setup prompt page" do
      expect(page.body).to include("Make your account more secure")
      assert_not_access_granted user, application
    end
  end

  it "does not authorise access to the application if the user has not passed 2FA" do
    visit "/oauth/authorize?response_type=code&client_id=#{application.uid}&redirect_uri=#{application.redirect_uri}"
    signin_with(user, second_step: false)

    expect(page.body).to include("Use the app on your phone to get your 6-digit 2FA code")
    assert_not_access_granted user, application
  end

  it "does not authorise access to the application for a user without 'signin' permission for the application" do
    visit "/oauth/authorize?response_type=code&client_id=#{application.uid}&redirect_uri=#{application.redirect_uri}"
    signin_with(user)

    expect(page.body).to include("You don’t have permission to sign in to #{application.name}.")
    assert_not_access_granted user, application
  end

  it "authorises access to the application for a signed in user with 'signin' permission for the application" do
    user.grant_application_signin_permission(application)
    visit "/oauth/authorize?response_type=code&client_id=#{application.uid}&redirect_uri=#{application.redirect_uri}"
    signin_with(user)

    assert_redirected_to_application application
    assert_access_granted user, application
  end

private

  def assert_redirected_to_application(app)
    expect(current_url).to match(/^#{app.redirect_uri}/)
    expect(current_url).to match(/\?code=/)
  end

  def assert_access_granted(user, app)
    expect(access_grant_for(user, app)).not_to be_nil, "Expected #{user.email} (ID #{user.id}) to have been granted access to #{app.name} (ID #{app.id}) but no matching AccessGrant found."
  end

  def assert_not_access_granted(user, app)
    expect(access_grant_for(user, app)).to be_nil, "Expected #{user.email} (ID #{user.id}) not to have been granted access to #{app.name} (ID #{app.id}) but a matching AccessGrant was found."
  end

  def access_grant_for(user, app)
    Doorkeeper::AccessGrant.find_by(resource_owner_id: user, application: app)
  end
end
