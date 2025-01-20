require "rails_helper"

RSpec.describe "Sign out", type: :system do
  it "does not blow up if not already signed in" do
    signout
    expect(page).to have_text("Sign in to Publishing Platform")
  end
end
