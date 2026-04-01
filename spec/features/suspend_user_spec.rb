require "rails_helper"

RSpec.feature "Suspend user", type: :feature do
  let(:admin_user) { create(:admin_user) }
  let(:user) { create(:user) }

  scenario do
    given_a_signed_in_admin_user
    when_i_visit_edit_user_page(user)
    and_i_click_suspend_user
    and_i_submit_suspend_user_form("gross misconduct")
    then_i_see_a_message_that_user_is_suspended
  end

  scenario "entering an empty suspension reason" do
    given_a_signed_in_admin_user
    when_i_visit_edit_user_page(user)
    and_i_click_suspend_user
    and_i_submit_suspend_user_form("")
    then_i_see_a_validation_error_message
  end

  context "when user is suspended" do
    let(:user) { create(:suspended_user) }

    scenario "signing in when user is suspended" do
      when_i_visit_path(new_user_session_path)
      and_i_sign_in_with(user)
      then_i_am_unable_to_sign_in
    end

    scenario "signing in after user is unsuspended" do
      given_a_signed_in_admin_user
      when_i_visit_edit_user_page(user)
      and_i_click_unsuspend_user
      and_i_submit_unsuspend_user_form
      then_i_see_a_message_that_user_is_active
      when_i_sign_out
      and_i_sign_in_with(user)
      then_user_password_has_been_reset
    end

    scenario "viewing suspension reason" do
      given_a_signed_in_admin_user
      when_i_visit_edit_user_page(user)
      then_i_can_see_why_the_user_was_suspended
    end
  end

private

  def given_a_signed_in_admin_user
    visit new_user_session_path
    expect(page).to have_text("Sign in to Publishing Platform")

    signin_with(admin_user)
    expect(page).to have_text("Signed in successfully")

    complete_2fa_step(admin_user)

    expect(page).to have_text("Your applications")
    expect(page).to have_current_path(root_path)
  end

  def when_i_visit_path(path)
    visit path
  end

  def and_i_sign_in_with(user)
    expect(page).to have_text("Sign in to Publishing Platform")
    signin_with(user)
  end

  def when_i_sign_out
    signout
  end

  def then_i_am_unable_to_sign_in
    expect(page).to have_text("Your account has been suspended.")
    expect(page).to have_text("Sign in to Publishing Platform")
  end

  def when_i_visit_edit_user_page(user)
    visit edit_user_path(user)
    expect(page).to have_text("Edit #{user.name}")
  end

  def and_i_click_suspend_user
    click_link "Suspend user"
  end

  def and_i_click_unsuspend_user
    click_link "Unsuspend user"
  end

  def and_i_submit_suspend_user_form(reason)
    check "user_suspended"
    fill_in "user_reason_for_suspension", with: reason

    click_button "Save"
  end

  def and_i_submit_unsuspend_user_form
    uncheck "user_suspended"
    click_button "Save"
  end

  def then_i_see_a_validation_error_message
    expect(page).to have_text("Reason for suspension can't be blank")
  end

  def then_i_see_a_message_that_user_is_suspended
    expect(page).to have_text("#{user.email} is now suspended.")
  end

  def then_i_see_a_message_that_user_is_active
    expect(page).to have_text("#{user.email} is now active.")
  end

  def then_user_password_has_been_reset
    expect(page).to have_text("Invalid email or password")
  end

  def then_i_can_see_why_the_user_was_suspended
    expect(page).to have_selector("div[role='alert'] h2", text: "User suspended")
    expect(page).to have_selector("div[role='alert'] em", text: user.reason_for_suspension)
  end
end
