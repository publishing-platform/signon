require "rails_helper"

RSpec.describe "User locking", type: :system do
  let(:user) { create(:user) }

  it "triggers if the user types a wrong password too many times" do
    visit root_path
    6.times { signin_with(email: user.email, password: "wrong password", second_step: false) }

    signin_with(user, second_step: false)

    expect(last_email.to[0]).to eql user.email
    expect(last_email.subject).to match(/Your .* Signon development account has been locked/)

    expect(page).to have_text("Invalid email or password.")

    user.reload
    expect(user.access_locked?).to be true
  end

  it "is reversible from the user edit page" do
    admin = create(:admin_user)
    user.lock_access!

    visit root_path
    signin_with(admin)
    visit edit_user_path(user)

    click_button "Unlock account"

    expect(page).to have_text("Unlocked #{user.email}")

    user.reload
    expect(user.access_locked?).to be false

    signout

    signin_with(user)

    expect(page).to have_text("Your applications")
  end
end
