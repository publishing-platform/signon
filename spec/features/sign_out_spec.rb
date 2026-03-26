require "rails_helper"

RSpec.describe "Sign out", type: :feature do
  scenario "signing out when not already signed in" do
    when_i_sign_out
    then_i_see_the_signin_page
  end

private

  def when_i_sign_out
    signout
  end

  def then_i_see_the_signin_page
    expect(page).to have_text("Sign in to Publishing Platform")
  end
end
