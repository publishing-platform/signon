require "rails_helper"

RSpec.describe "Creating password", type: :system do
  let(:user) { User.invite!(name: "Joe Bloggs", email: "joe.bloggs@example.com") }

  before do
    visit accept_user_invitation_path(invitation_token: user.raw_invitation_token)
  end

  it "creates password if sufficiently strong" do
    password = "0871feaffef29223358cbf086b4084c4"
    fill_in "New password", with: password
    fill_in "Confirm new password", with: password
    click_button "Save password"

    expect(page.body).to have_text("Your password was set successfully.")

    fill_in "Email", with: user.email
    fill_in "Password", with: password
    click_button "Sign in"

    expect(page.body).to have_text("Make your account more secure by setting up 2‑Factor Authentication")
  end

  it "rejects password if too short" do
    password = "0871feaff"
    fill_in "New password", with: password
    fill_in "Confirm new password", with: password
    click_button "Save password"

    expect(page.body).to have_text("Password is too short (minimum is 10 characters)")
  end

  it "rejects blank password" do
    fill_in "New password", with: ""
    fill_in "Confirm new password", with: ""
    click_button "Save password"

    expect(page.body).to have_text("Password can't be blank")
  end

  it "rejects password that does not match password confirmation" do
    password = "0871feaff"
    fill_in "New password", with: password
    fill_in "Confirm new password", with: "#{password}extra"
    click_button "Save password"

    expect(page.body).to have_text("Password confirmation doesn't match Password")
  end
end
