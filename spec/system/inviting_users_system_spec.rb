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
  end

  it "allows invitation to be resent" do
    signin_with(user)
    visit new_user_invitation_path

    fill_in "Name", with: "Joe Bloggs"
    fill_in "Email", with: "fred@example.com"
    click_button "Create user and send email"

    invited = User.find_by(email: "fred@example.com")
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
