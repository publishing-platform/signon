require "rails_helper"

RSpec.describe "Sign in", type: :system do
  let(:organisation) { create(:organisation, name: "Ministry of Lindy-hop", slug: "ministry-of-lindy-hop") }
  let(:email) { "email@example.com" }
  let(:password) { "some password with various $ymb0l$" }
  let!(:user) { create(:user, email:, password:, organisation:) }

  it "displays a confirmation for successful sign-ins" do
    visit root_path
    signin_with(email:, password:)
    assert_user_is_signed_in
  end

  it "displays a rejection for unsuccessful sign-ins" do
    visit root_path
    signin_with(email:, password: "some incorrect password with various $ymb0l$", second_step: false)
    assert_signin_fail
  end

  it "displays the same rejection for failed logins, empty passwords, and missing accounts" do
    visit root_path
    signin_with(email: "does-not-exist@example.com", password: "some made up p@ssw0rd")
    assert_signin_fail

    visit root_path
    signin_with(email:, password: "some incorrect password with various $ymb0l$", second_step: false)
    assert_signin_fail

    visit root_path
    signin_with(email:, password: "", second_step: false)
    assert_signin_fail
  end

  context "with a 2FA secret" do
    before do
      user.update!(otp_secret: ROTP::Base32.random_base32)
    end

    it "prompts for a 2FA code" do
      visit root_path
      signin_with(email:, password:, second_step: false)
      expect(page).to have_text("Use the app on your phone to get your 6-digit 2FA code")
      assert_selector "input[name=code]"
    end

    it "does not prompt for a 2FA code twice per browser in 30 days" do
      visit root_path
      signin_with(email:, password:)
      assert_user_is_signed_in

      signout

      Timecop.travel(29.days.from_now) do
        visit root_path
        signin_with(email:, password:, second_step: false)
        assert_user_is_signed_in
      end

      signout

      Timecop.travel(31.days.from_now) do
        visit root_path
        signin_with(email:, password:, second_step: false)
        expect(page).to have_text("Use the app on your phone to get your 6-digit 2FA code")
        assert_selector "input[name=code]"
      end
    end

    it "prevents access to signon until fully authenticated" do
      visit root_path
      signin_with(email:, password:, second_step: false)
      visit root_path
      expect(page).to have_text("Use the app on your phone to get your 6-digit 2FA code")
      assert_selector "input[name=code]"
    end

    it "allows access with a correctly-generated code" do
      visit root_path
      signin_with(email:, password:)
      assert_user_is_signed_in
    end

    it "prevents access with a blank code" do
      visit root_path
      signin_with(email:, password:, second_step: "")

      expect(page).to have_text("Use the app on your phone to get your 6-digit 2FA code")
      assert_selector "input[name=code]"
    end

    it "prevents access with an old code" do
      old_code = Timecop.freeze(2.minutes.ago) { ROTP::TOTP.new(user.otp_secret).now }

      visit root_path
      signin_with(email:, password:, second_step: old_code)

      expect(page).to have_text("Use the app on your phone to get your 6-digit 2FA code")
      assert_selector "input[name=code]"
    end

    it "prevents access with a garbage code" do
      visit root_path
      signin_with(email:, password:, second_step: "abcdef")

      expect(page).to have_text("Use the app on your phone to get your 6-digit 2FA code")
      assert_selector "input[name=code]"
    end

    it "does not remember a user's 2FA session if they've changed 2FA secret" do
      visit root_path
      signin_with(email:, password:)
      assert_user_is_signed_in

      signout
      visit root_path

      user.update!(otp_secret: ROTP::Base32.random_base32)
      signin_with(email:, password:, second_step: false)

      expect(page).to have_text("Use the app on your phone to get your 6-digit 2FA code")
      assert_selector "input[name=code]"
    end

    it "forces user to set up 2FA again if 2FA is disabled for user with a remembered session" do
      visit root_path
      signin_with(email:, password:)
      assert_user_is_signed_in

      signout
      visit root_path

      user.update!(otp_secret: nil)
      signin_with(email:, password:, second_step: false, set_up_2fa: false)

      expect(page).to have_text("Make your account more secure by setting up 2‑Factor Authentication")
    end

    it "allows the user to cancel 2FA by signing out" do
      visit root_path
      signin_with(email:, password:, second_step: false)
      click_link "Sign out"

      expect(page).to have_text("Sign in to Publishing Platform")
    end

    it "does not allow access to restricted paths before completing 2FA" do
      visit root_path
      signin_with(email:, password:, second_step: false)
      expect(page).to have_current_path(new_two_factor_authentication_session_path)

      # TODO: This list should be complete
      restricted_paths = [
        oauth_authorization_path,
        new_user_password_path,
        edit_user_password_path,
        new_user_confirmation_path,
        user_confirmation_path,
        accept_user_invitation_path,
        remove_user_invitation_path,
        new_user_invitation_path,
        prompt_two_factor_authentication_path,
        two_factor_authentication_path,
        users_path,
        oauth_applications_path,
        api_users_path,
      ]

      restricted_paths.each do |path|
        visit path
        expect(page).to have_current_path(new_two_factor_authentication_session_path)
      end
    end
  end

  it "does not allow access to the 2FA login page before logging in" do
    signout
    visit new_two_factor_authentication_session_path
    expect(page).to have_current_path("/users/sign_in")
  end

  def assert_user_is_signed_in
    expect(page).to have_text("Your applications")
  end

  def assert_signin_fail
    expect(page).to have_text("Invalid email or password")
  end
end
