require "rails_helper"

RSpec.describe "Invite users", type: :feature do
  context "when sending an invitation" do
    let(:user) { create(:admin_user) }

    scenario "submitting the invitation form" do
      given_a_signed_in_user
      when_i_visit_the_new_user_invitation_page
      then_i_see_the_new_user_invitation_form
      when_i_fill_in_and_submit_the_new_user_invitation_form
      then_i_see_an_invitation_confirmation_message
      and_an_invitation_email_is_sent
    end

    scenario "resending an invitation" do
      given_an_invited_user
      and_given_a_signed_in_user
      when_i_visit_the_edit_user_page
      then_i_see_invitation_not_yet_accepted_message
      when_i_resend_invitation_email
      then_the_invitation_email_is_resent
    end

    scenario "inviting an existing user" do
      given_an_existing_user
      and_given_a_signed_in_user
      when_i_visit_the_new_user_invitation_page
      then_i_see_the_new_user_invitation_form
      when_i_fill_in_and_submit_the_new_user_invitation_form
      then_i_see_a_message_that_user_already_exists
      and_an_invitation_email_is_not_sent
    end
  end

  context "when accepting an invitation" do
    scenario "setting password and signing in" do
      given_an_invited_user
      when_i_visit_the_invitation_link_in_the_email
      then_i_see_the_set_password_page
      when_i_enter_a_password_that_is_sufficiently_strong
      then_i_see_password_set_successfully_message
      and_i_am_required_to_sign_in
    end
  end

private

  def given_a_signed_in_user
    visit new_user_session_path
    expect(page).to have_text("Sign in to Publishing Platform")

    signin_with(user)
    expect(page).to have_text("Signed in successfully")

    complete_2fa_step(user)

    expect(page).to have_text("Your applications")
    expect(page).to have_current_path(root_path)
  end

  alias_method :and_given_a_signed_in_user, :given_a_signed_in_user

  def when_i_visit_the_new_user_invitation_page
    visit new_user_invitation_path
  end

  def then_i_see_the_new_user_invitation_form
    expect(page).to have_selector("form.new_user")
  end

  def when_i_fill_in_and_submit_the_new_user_invitation_form
    fill_in "Name", with: "Joe Bloggs"
    fill_in "Email", with: "joe@example.com"
    click_button "Create user and send email"
  end

  def then_i_see_an_invitation_confirmation_message
    expect(page).to have_text("An invitation email has been sent to joe@example.com.")
  end

  def when_i_sign_out
    signout
  end

  def then_i_see_the_sign_in_page
    expect(page).to have_text("Sign in to Publishing Platform")
  end

  def when_i_visit_the_invitation_link_in_the_email
    path = last_email.body.match(/(?:https?:\/\/.*?)(\/.*)/)[1]
    visit path
  end

  def then_i_see_the_set_password_page
    expect(page).to have_text("Set your password")
  end

  def when_i_enter_a_password_that_is_sufficiently_strong
    fill_in "New password", with: "this 1s 4 v3333ry s3cur3 p4ssw0rd.!Z"
    fill_in "Confirm new password", with: "this 1s 4 v3333ry s3cur3 p4ssw0rd.!Z"
    click_button "Save password"
  end

  def then_i_see_password_set_successfully_message
    expect(page).to have_text("Your password was set successfully.")
  end

  def given_an_existing_user
    create(:user, email: "joe@example.com", name: "Joe Bloggs")
  end

  def given_an_invited_user
    User.invite!(name: "Joe Bloggs", email: "joe@example.com")
  end

  def then_i_see_a_message_that_user_already_exists
    expect(page).to have_text("User already invited. If you want to, you can click 'Resend signup email'.")
  end

  def and_an_invitation_email_is_not_sent
    emails_received = all_emails.count { |email| email.subject == "Invitation instructions" }
    expect(emails_received).to be 0
  end

  def and_an_invitation_email_is_sent
    emails_received = all_emails.count { |email| email.subject == "Invitation instructions" }
    expect(emails_received).to be 1
  end

  def then_the_invitation_email_is_resent
    expect(page).to have_text("Resent account signup email to joe@example.com")
    emails_received = all_emails.count { |email| email.subject == "Invitation instructions" }
    expect(emails_received).to be 2
  end

  def when_i_visit_the_edit_user_page
    invited = User.find_by(email: "joe@example.com")
    visit edit_user_path(invited)
  end

  def then_i_see_invitation_not_yet_accepted_message
    expect(page).to have_text("Invitation not accepted yet")
  end

  def when_i_resend_invitation_email
    click_button "Resend signup email"
  end

  def and_i_am_required_to_sign_in
    expect(page).to have_text("Sign in to Publishing Platform")
    signin_with(email: "joe@example.com", password: "this 1s 4 v3333ry s3cur3 p4ssw0rd.!Z", set_up_2fa: false)
    expect(page).to have_text("Make your account more secure by setting up 2‑Factor Authentication")
  end
end
