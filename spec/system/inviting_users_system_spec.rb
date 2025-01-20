require "rails_helper"

RSpec.describe "Inviting users", type: :system do
  let(:user) { create(:admin_user) }
  # let!(:organisation) { create(:organisation) }

  before do
    visit new_user_session_path
  end

  it "sends invitation containing token allowing new user to set their password" do
    signin_with(user)
    visit new_user_invitation_path

    fill_in "Name", with: "Joe Bloggs"
    fill_in "Email", with: "fred@example.com"
    click_button "Create user and send email"

    expect(page).to have_text("An invitation email has been sent to fred@example.com.")

    signout

    path = last_email.body.match(/(?:https?:\/\/.*?)(\/.*)/)[1]
    visit path

    expect(page).to have_text("Set your password")

    fill_in "New password", with: "this 1s 4 v3333ry s3cur3 p4ssw0rd.!Z"
    fill_in "Confirm new password", with: "this 1s 4 v3333ry s3cur3 p4ssw0rd.!Z"
    click_button "Save password"

    expect(page).to have_text("Your password was set successfully.")
  end

  it "requires invited user to sign in after setting their password" do
    user = User.invite!(name: "Joe Bloggs", email: "joe.bloggs@example.com")

    accept_invitation(
      invitation_token: user.raw_invitation_token,
      password: "pretext annoying headpiece waviness header slinky",
    )

    expect(page).to have_text("Sign in to Publishing Platform")

    fill_in "Email", with: "joe.bloggs@example.com"
    fill_in "Password", with: "pretext annoying headpiece waviness header slinky"
    click_button "Sign in"

    expect(page).to have_text("Make your account more secure by setting up 2‑Factor Authentication")
  end

  it "allows invitation to be resent" do
    signin_with(user)
    visit new_user_invitation_path

    fill_in "Name", with: "Joe Bloggs"
    fill_in "Email", with: "joe.bloggs@example.com"
    click_button "Create user and send email"

    invited = User.find_by(email: "joe.bloggs@example.com")
    visit edit_user_path(invited)

    click_button "Resend signup email"

    expect(page).to have_text("Resent account signup email to #{invited.email}")

    signout

    emails_received = all_emails.count { |email| email.subject == "Invitation instructions" }
    expect(emails_received).to be 2
  end

  it "prevents existing user being invited" do
    existing_user = create(:user)

    signin_with(user)
    visit new_user_invitation_path

    fill_in "Name", with: existing_user.name
    fill_in "Email", with: existing_user.email
    click_button "Create user and send email"

    expect(page).to have_text("User already invited. If you want to, you can click 'Resend signup email'.")

    signout

    emails_received = all_emails.count { |email| email.subject == "Invitation instructions" }
    expect(emails_received).to be 0
  end
end
