require "rails_helper"

RSpec.describe "Two Factor Authentication prompt", type: :system do
  let(:user) { create(:admin_user) }

  before do
    visit users_path
    signin_with(user, set_up_2fa: false)
  end

  it "prompts the user to complete 2FA set up" do
    expect(page).to have_text("Make your account more secure by setting up 2‑Factor Authentication.")
  end

  context "when they try to access something else" do
    it "ensures the prompt is still displayed" do
      visit users_path

      expect(page).to have_text("Make your account more secure by setting up 2‑Factor Authentication.")
    end
  end

  context "when they choose to setup 2FA" do
    it "directs them to setup" do
      secret = ROTP::Base32.random_base32
      allow(ROTP::Base32).to receive(:random_base32).and_return(secret)

      click_link "Start set up"

      expect(page).to have_text("Set up 2-Factor Authentication (2FA)")

      enter_2fa_code(secret)
      click_button "Finish set up"

      expect(page).to have_text("2-Factor Authentication set up")
      expect(page).to have_current_path(users_path)
    end

    it "displays failure message if incorrect code entered" do
      secret = ROTP::Base32.random_base32

      click_link "Start set up"

      expect(page).to have_text("Set up 2-Factor Authentication (2FA)")

      enter_2fa_code(secret)
      click_button "Finish set up"

      expect(page).to have_text("Sorry, that code didn't work.")
    end
  end
end
