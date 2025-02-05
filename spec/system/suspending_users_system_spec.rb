require "rails_helper"

RSpec.describe "Suspending users", type: :system do
  let(:user) { create(:admin_user) }

  before do
    visit new_user_session_path
    signin_with(user)
  end

  it "allows user to be suspended, preventing signin" do
    active_user = create(:active_user)

    visit edit_user_path(active_user)

    click_link "Suspend user"

    check "user_suspended"
    fill_in "user_reason_for_suspension", with: "gross misconduct"

    click_button "Save"

    expect(page).to have_text("#{active_user.email} is now suspended.")

    signout

    signin_with(active_user, second_step: false)

    expect(page).to have_text("Your account has been suspended.")
    expect(page).to have_text("Sign in to Publishing Platform")
  end

  it "allows a suspended user to be unsuspended, resetting their password" do
    suspended_user = create(:suspended_user)

    visit edit_user_path(suspended_user)
    click_link "Unsuspend user"

    uncheck "user_suspended"

    click_button "Save"

    expect(page).to have_text("#{suspended_user.email} is now active.")

    signout

    signin_with(suspended_user, second_step: false)

    expect(page).to have_text("Invalid email or password")
  end

  it "shows suspension reason to admins" do
    suspended_user = create(:suspended_user, reason_for_suspension: "gross misconduct")

    visit edit_user_path(suspended_user)

    expect(page).to have_selector("div[role='alert'] h2", text: "User suspended")
    expect(page).to have_selector("div[role='alert'] em", text: "gross misconduct")
  end
end
