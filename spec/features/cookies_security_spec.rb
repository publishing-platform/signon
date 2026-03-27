require "rails_helper"

RSpec.feature "Cookies security", type: :feature do
  let(:user) { create(:two_factor_enabled_user) }

  scenario "set the right cookies when signing in" do
    when_user_signs_in
    then_cookies_have_secure_attributes
  end

private

  def when_user_signs_in
    visit new_user_session_path
    expect(page).to have_text("Sign in to Publishing Platform")

    signin_with(user)
    expect(page).to have_text("Signed in successfully")
  end

  def then_cookies_have_secure_attributes
    response_cookies = page.driver.browser.manage.all_cookies
    response_cookies.each do |cookie|
      expect(cookie[:same_site]).to eql "Lax"
      expect(cookie[:http_only]).to be true
    end
  end
end
