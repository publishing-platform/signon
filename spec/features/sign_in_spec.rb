require "rails_helper"

RSpec.feature "Sign in", type: :feature do
  let(:organisation) { create(:organisation, name: "Ministry of Lindy-hop", slug: "ministry-of-lindy-hop") }
  let(:email) { "email@example.com" }
  let(:password) { "some password with various $ymb0l$" }
  let!(:user) { create(:user, email:, password:, organisation:) }

  scenario "successful sign in" do
    when_i_sign_in_with(email:, password:)
    then_i_am_prompted_for_2fa
    when_i_complete_2fa
    then_sign_in_succeeds
  end

  scenario "entering an incorrect password" do
    when_i_sign_in_with(email:, password: "some incorrect password with various $ymb0l$")
    then_sign_in_fails
  end

  scenario "entering an empty password" do
    when_i_sign_in_with(email:, password: "")
    then_sign_in_fails
  end

  scenario "missing account" do
    when_i_sign_in_with(email: "does-not-exist@example.com", password: "some made up p@ssw0rd")
    then_sign_in_fails
  end

  context "with 2FA secret" do
    before do
      user.update!(otp_secret: ROTP::Base32.random_base32)
    end

    scenario "does not prompt for a 2FA code twice per browser in 30 days" do
      when_i_sign_in_with(email:, password:)
      then_i_am_prompted_for_2fa
      when_i_complete_2fa
      then_sign_in_succeeds

      when_i_sign_out

      Timecop.travel(29.days.from_now) do
        and_i_sign_in_with(email:, password:)
        then_sign_in_succeeds
      end

      when_i_sign_out

      Timecop.travel(31.days.from_now) do
        and_i_sign_in_with(email:, password:)
        then_i_am_prompted_for_2fa
      end
    end

    scenario "access to signon prevented until fully authenticated" do
      when_i_sign_in_with(email:, password:)
      then_i_am_prompted_for_2fa
      when_i_navigate_to_home_page
      then_i_am_prompted_for_2fa
    end

    scenario "entering a blank 2FA code" do
      when_i_sign_in_with(email:, password:)
      then_i_am_prompted_for_2fa
      when_i_complete_2fa(code: "")
      then_i_am_prompted_for_2fa
    end

    scenario "entering an old 2FA code" do
      old_code = Timecop.freeze(2.minutes.ago) { ROTP::TOTP.new(user.otp_secret).now }

      when_i_sign_in_with(email:, password:)
      then_i_am_prompted_for_2fa
      when_i_complete_2fa(code: old_code)
      then_i_am_prompted_for_2fa
    end

    scenario "entering a garbage 2FA code" do
      when_i_sign_in_with(email:, password:)
      then_i_am_prompted_for_2fa
      when_i_complete_2fa(code: "abcdef")
      then_i_am_prompted_for_2fa
    end

    scenario "does not remember a user's 2FA session if they've changed 2FA secret" do
      when_i_sign_in_with(email:, password:)
      then_i_am_prompted_for_2fa
      when_i_complete_2fa
      then_sign_in_succeeds
      when_i_sign_out
      and_update_2fa_secret
      and_i_sign_in_with(email:, password:)
      then_i_am_prompted_for_2fa
    end

    scenario "force user to set up 2FA again if 2FA is disabled for user with a remembered session" do
      when_i_sign_in_with(email:, password:)
      then_i_am_prompted_for_2fa
      when_i_complete_2fa
      then_sign_in_succeeds
      when_i_sign_out
      and_2fa_is_disabled
      and_i_sign_in_with(email:, password:, set_up_2fa: false)
      then_i_am_prompted_to_set_up_2fa
    end

    scenario "cancel 2FA by signing out" do
      when_i_sign_in_with(email:, password:)
      then_i_am_prompted_for_2fa
      when_i_click_signout_link
      then_i_see_the_signin_page
    end

    scenario "attempting to access restricted paths before completing 2FA" do
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

      when_i_sign_in_with(email:, password:, set_up_2fa: false)
      then_i_am_prompted_for_2fa

      restricted_paths.each do |path|
        when_i_visit_path(path)
        then_i_am_prompted_for_2fa
      end
    end

    scenario "attempting to access 2FA step before signing in" do
      when_i_navigate_to_home_page
      then_i_see_the_signin_page
      when_i_visit_path(new_two_factor_authentication_session_path)
      then_i_see_the_signin_page
    end
  end

private

  def when_i_navigate_to_home_page
    visit root_path
  end

  def when_i_sign_in_with(email: nil, password: nil, set_up_2fa: true)
    visit root_path
    expect(page).to have_text("Sign in to Publishing Platform")
    signin_with(email:, password:, set_up_2fa:)
  end

  alias_method :and_i_sign_in_with, :when_i_sign_in_with

  def then_i_am_prompted_for_2fa
    expect(page).to have_text("Use the app on your phone to get your 6-digit 2FA code")
    expect(page).to have_selector("input[name=code]")
  end

  def when_i_complete_2fa(code: nil)
    complete_2fa_step(email:, code:)
  end

  def then_sign_in_succeeds
    expect(page).to have_text("Your applications")
  end

  def then_sign_in_fails
    expect(page).to have_text("Invalid email or password")
  end

  def when_i_sign_out
    signout
    expect(page).to have_text("Sign in to Publishing Platform")
  end

  def when_i_click_signout_link
    click_link "Sign out"
  end

  def then_i_see_the_signin_page
    expect(page).to have_text("Sign in to Publishing Platform")
  end

  def and_update_2fa_secret
    user.update!(otp_secret: ROTP::Base32.random_base32)
  end

  def and_2fa_is_disabled
    user.update!(otp_secret: nil)
  end

  def then_i_am_prompted_to_set_up_2fa
    expect(page).to have_text("Make your account more secure by setting up 2‑Factor Authentication")
  end

  def when_i_visit_path(path)
    visit path
  end
end
