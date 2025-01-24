require "rails_helper"

RSpec.describe "Cookies security", type: :system do
  let(:user) { create(:two_factor_enabled_user) }

  it "set the right cookies when signing in" do
    visit new_user_session_path
    signin_with(user)

    response_cookies = page.driver.browser.manage.all_cookies
    response_cookies.each do |cookie|
      expect(cookie[:same_site]).to eql "Lax"
      expect(cookie[:http_only]).to be true
    end
  end
end
