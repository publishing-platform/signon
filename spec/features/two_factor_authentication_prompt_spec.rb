require "rails_helper"

RSpec.feature "Two Factor Authentication prompt", type: :feature do
  let(:user) { create(:admin_user) }

  scenario "setting up 2FA with a correct code" do
    secret = ROTP::Base32.random_base32
    allow(ROTP::Base32).to receive(:random_base32).and_return(secret)

    when_i_visit_users_page
    and_i_sign_in
    then_i_am_prompted_to_set_up_2fa
    when_i_click_start_set_up
    then_i_see_the_2fa_set_up_page
    when_i_submit_2fa_code(secret)
    then_i_see_a_success_message
    and_i_am_redirected_to_users_page
  end

  scenario "setting up 2FA with an incorrect code" do
    secret = ROTP::Base32.random_base32

    when_i_visit_sign_in_page
    and_i_sign_in
    then_i_am_prompted_to_set_up_2fa
    when_i_click_start_set_up
    then_i_see_the_2fa_set_up_page
    when_i_submit_2fa_code(secret)
    then_i_see_an_error_message
  end

  scenario "attempting to access something else before 2FA is setup" do
    when_i_visit_sign_in_page
    and_i_sign_in
    then_i_am_prompted_to_set_up_2fa
    when_i_visit_users_page
    then_i_am_prompted_to_set_up_2fa
  end

private

  def when_i_visit_sign_in_page
    visit new_user_session_path
  end

  def and_i_sign_in
    expect(page).to have_text("Sign in to Publishing Platform")
    signin_with(user, set_up_2fa: false)
  end

  def then_i_am_prompted_to_set_up_2fa
    expect(page).to have_text("Make your account more secure by setting up 2‑Factor Authentication.")
  end

  def when_i_visit_users_page
    visit users_path
  end

  def when_i_click_start_set_up
    click_link "Start set up"
  end

  def then_i_see_the_2fa_set_up_page
    expect(page).to have_text("Set up 2-Factor Authentication (2FA)")
  end

  def when_i_submit_2fa_code(secret)
    enter_2fa_code(secret)
    click_button "Finish set up"
  end

  def then_i_see_a_success_message
    expect(page).to have_text("2-Factor Authentication set up")
  end

  def then_i_see_an_error_message
    expect(page).to have_text("Sorry, that code didn't work.")
  end

  def and_i_am_redirected_to_users_page
    expect(page).to have_current_path(users_path)
  end
end
