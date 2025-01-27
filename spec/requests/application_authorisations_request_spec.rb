require "rails_helper"

RSpec.describe "Application authorisations", type: :request do
  let(:application) { create(:oauth_application) }
  let(:user) { create(:user) }

  context "when user is not authenticated" do
    it "redirects user to sign in" do
      get "/oauth/authorize?response_type=code&client_id=#{application.uid}&redirect_uri=#{application.redirect_uri}"

      assert_not_authenticated
    end
  end

  context "when the user has had 2FA mandated" do
    before do
      user.update!(require_2fa: true)
      sign_in(user, require_2fa: true)
      get "/oauth/authorize?response_type=code&client_id=#{application.uid}&redirect_uri=#{application.redirect_uri}"
    end

    it "does not authorise access to the application and redirects to 2FA setup prompt page" do
      follow_redirect!
      expect(response.body).to include("Make your account more secure")
      assert_not_access_granted user, application
    end
  end

  it "does not authorise access to the application if the user has not passed 2FA" do
    user.update!(otp_secret: ROTP::Base32.random_base32)

    sign_in(user, require_2fa: true)
    get "/oauth/authorize?response_type=code&client_id=#{application.uid}&redirect_uri=#{application.redirect_uri}"

    follow_redirect!

    expect(response.body).to include("Use the app on your phone to get your 6-digit 2FA code")
    assert_not_access_granted user, application
  end

  it "does not authorise access to the application for a user without 'signin' permission for the application" do
    sign_in(user)
    get "/oauth/authorize?response_type=code&client_id=#{application.uid}&redirect_uri=#{application.redirect_uri}"

    follow_redirect!
    expect(response.body).to include("You don’t have permission to sign in to #{application.name}.")
    assert_not_access_granted user, application
  end

  it "authorises access to the application for a signed in user with 'signin' permission for the application" do
    user.grant_application_signin_permission(application)
    sign_in(user)
    get "/oauth/authorize?response_type=code&client_id=#{application.uid}&redirect_uri=#{application.redirect_uri}"

    assert_redirected_to_application application
    assert_access_granted user, application
  end

private

  def assert_redirected_to_application(app)
    expect(response.location).to match(/^#{app.redirect_uri}/)
    expect(response.location).to match(/\?code=/)
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
