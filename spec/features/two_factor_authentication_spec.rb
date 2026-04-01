require "rails_helper"

RSpec.feature "Two Factor Authentication", type: :feature do
  let!(:new_secret) { ROTP::Base32.random_base32 }
  let!(:original_secret) { ROTP::Base32.random_base32 }
  let(:user) { create(:user, email: "jane.user@example.com") }

  before do
    allow(ROTP::Base32).to receive(:random_base32).and_return(new_secret)
  end

  context "when user does not have an existing 2FA setup" do
    scenario "setting up 2FA" do
      given_a_signed_in_user
      when_i_visit_the_2fa_setup_page
      then_i_am_shown_the_totp_secret
      when_i_enter_an_invalid_code
      then_i_am_shown_a_rejection_message
      when_i_enter_a_valid_code
      then_i_am_shown_a_success_message
      and_the_secret_is_persisted
      when_i_sign_out_and_sign_in_again
      then_i_am_prompted_for_a_2fa_code
    end

    scenario "setting up 2FA from a device with a time lag" do
      given_a_signed_in_user
      when_i_visit_the_2fa_setup_page
      then_i_am_shown_the_totp_secret
      when_i_enter_a_valid_code_from_a_device_which_has_a_small_time_lag
      then_i_am_shown_a_success_message
      and_the_secret_is_persisted
    end

    scenario "visiting the 2FA sign-in page when 2FA is mandated (default)" do
      given_a_signed_in_user
      when_i_visit_the_2fa_sign_in_page
      then_i_am_redirected_to_the_2fa_setup_prompt_page
    end

    scenario "visiting the 2FA sign-in page when 2FA is not mandated" do
      user.update!(require_2fa: false)
      given_a_signed_in_user
      when_i_visit_the_2fa_sign_in_page
      then_i_am_redirected_to_the_home_page
    end
  end

  context "when user has an existing 2FA setup" do
    let(:user) { create(:user, email: "jane.user@example.com", otp_secret: original_secret) }

    scenario "updating 2FA device" do
      given_a_signed_in_user
      when_2fa_has_been_completed
      then_i_am_redirected_to_the_home_page
      when_i_visit_the_2fa_setup_page
      then_i_am_shown_the_totp_secret
      and_i_am_shown_a_warning_about_replacing_the_existing_phone
      when_i_enter_an_invalid_code("Finish replacing your phone")
      then_i_am_shown_a_rejection_message
      when_i_enter_a_valid_code("Finish replacing your phone")
      then_i_am_shown_a_success_message("2-Factor Authentication phone changed successfully")
      and_the_secret_is_persisted
      and_i_am_redirected_to_the_home_page
      when_i_sign_out_and_sign_in_again
      then_i_am_prompted_for_a_2fa_code
    end
  end

private

  def given_a_signed_in_user
    visit new_user_session_path
    expect(page).to have_text("Sign in to Publishing Platform")

    signin_with(user, set_up_2fa: false)
    expect(page).to have_text("Signed in successfully")
  end

  def when_i_visit_the_2fa_setup_page
    visit two_factor_authentication_path
  end

  def then_i_am_shown_the_totp_secret
    expect(page).to have_text("Enter this code when asked: #{new_secret}")
  end

  def when_i_enter_an_invalid_code(button_text = "Finish set up")
    fill_in "code", with: "abcdef"
    click_button button_text
  end

  def then_i_am_shown_a_rejection_message
    expect(page).to have_text("Sorry, that code didn't work.")
    expect(page).to have_text("Enter this code when asked: #{new_secret}")
  end

  def when_i_enter_a_valid_code(button_text = "Finish set up")
    enter_2fa_code(new_secret)
    click_button button_text
  end

  def then_i_am_shown_a_success_message(success_message = "2-Factor Authentication set up")
    expect(page).to have_text(success_message)
  end

  def and_the_secret_is_persisted
    expect(user.reload.otp_secret).to eql new_secret
  end

  def when_i_sign_out_and_sign_in_again
    click_link "Sign out"
    expect(page).to have_text("Sign in to Publishing Platform")

    signin_with(user)
    expect(page).to have_text("Signed in successfully")
  end

  def then_i_am_prompted_for_a_2fa_code
    expect(page).to have_text("Use the app on your phone to get your 6-digit 2FA code")
  end

  def when_i_enter_a_valid_code_from_a_device_which_has_a_small_time_lag
    old_code = Timecop.freeze(29.seconds.ago) { ROTP::TOTP.new(new_secret).now }

    Timecop.freeze do
      fill_in "code", with: old_code
      click_button "Finish set up"
    end
  end

  def when_i_visit_the_2fa_sign_in_page
    visit new_two_factor_authentication_session_path
  end

  def then_i_am_redirected_to_the_2fa_setup_prompt_page
    expect(page).to have_text("Make your account more secure by setting up 2‑Factor Authentication.")
    expect(page).to have_current_path(prompt_two_factor_authentication_path)
  end

  def then_i_am_redirected_to_the_home_page
    expect(page).to have_text("Your applications")
    expect(page).to have_current_path(root_path)
  end

  alias_method :and_i_am_redirected_to_the_home_page, :then_i_am_redirected_to_the_home_page

  def when_2fa_has_been_completed
    complete_2fa_step(user)
  end

  def and_i_am_shown_a_warning_about_replacing_the_existing_phone
    expect(page).to have_text("Setting up a new phone will replace your existing one. You will only be able to sign in with your new phone.")
  end
end
