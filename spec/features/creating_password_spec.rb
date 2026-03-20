require "rails_helper"

RSpec.describe "Creating password", type: :feature do
  let(:user) { User.invite!(name: "Joe Bloggs", email: "joe.bloggs@example.com") }
  let(:password) { "0871feaffef29223358cbf086b4084c4" }

  scenario "password is too short" do
    given_user_has_accepted_invitation
    then_i_am_asked_to_set_a_password
    when_i_enter_a_password_that_is_too_short
    then_i_am_shown_a_validation_error_message("Password is too short (minimum is 10 characters)")
  end

  scenario "password is blank" do
    given_user_has_accepted_invitation
    then_i_am_asked_to_set_a_password
    when_i_enter_a_blank_password
    then_i_am_shown_a_validation_error_message("Password can't be blank")
  end

  scenario "password does not match confirmation" do
    given_user_has_accepted_invitation
    then_i_am_asked_to_set_a_password
    when_i_enter_a_password_that_does_not_match_confirmation
    then_i_am_shown_a_validation_error_message("Password confirmation doesn't match Password")
  end

  scenario "password is sufficiently strong" do
    given_user_has_accepted_invitation
    then_i_am_asked_to_set_a_password
    when_i_enter_a_password_that_is_sufficiently_strong
    then_i_am_shown_a_success_message
    and_i_am_able_to_sign_in_with_the_new_password
  end

private

  def given_user_has_accepted_invitation
    visit accept_user_invitation_path(invitation_token: user.raw_invitation_token)
  end

  def then_i_am_asked_to_set_a_password
    expect(page).to have_text("Set your password")
  end

  def when_i_enter_a_password_that_is_too_short
    fill_in "New password", with: password.truncate(9)
    fill_in "Confirm new password", with: password.truncate(9)
    click_button "Save password"
  end

  def when_i_enter_a_blank_password
    fill_in "New password", with: ""
    fill_in "Confirm new password", with: ""
    click_button "Save password"
  end

  def when_i_enter_a_password_that_does_not_match_confirmation
    fill_in "New password", with: password
    fill_in "Confirm new password", with: "#{password}extra"
    click_button "Save password"
  end

  def when_i_enter_a_password_that_is_sufficiently_strong
    fill_in "New password", with: password
    fill_in "Confirm new password", with: password
    click_button "Save password"
  end

  def then_i_am_shown_a_validation_error_message(error_message)
    expect(page).to have_text(error_message)
  end

  def then_i_am_shown_a_success_message
    expect(page).to have_text("Your password was set successfully.")
  end

  def and_i_am_able_to_sign_in_with_the_new_password
    fill_in "Email", with: user.email
    fill_in "Password", with: password
    click_button "Sign in"

    expect(page).to have_text("Make your account more secure by setting up 2‑Factor Authentication")
  end
end
