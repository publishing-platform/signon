require "rails_helper"

RSpec.describe "Lock user", type: :feature do
  let(:user) { create(:user) }

  scenario "entering incorrect password too many times" do
    6.times do
      when_i_sign_in_with(email: user.email, password: "wrong password")
      then_sign_in_fails
    end

    and_user_account_is_locked
    and_account_locked_email_is_received
  end

  context "when user is locked" do
    let(:admin_user) { create(:admin_user) }
    let(:user) { create(:locked_user) }

    scenario "unlocking user" do
      when_i_sign_in_with(admin_user)
      then_i_am_prompted_for_a_2fa_code
      when_i_complete_2fa(admin_user)
      then_sign_in_succeeds
      when_i_visit_edit_user_page(user)
      and_i_unlock_user
      then_i_see_an_unlock_success_message
      and_user_account_is_unlocked
    end
  end

private

  def when_i_sign_in_with(user = nil, email: nil, password: nil, set_up_2fa: true)
    visit root_path
    expect(page).to have_text("Sign in to Publishing Platform")
    signin_with(user, email:, password:, set_up_2fa:)
  end

  def then_sign_in_fails
    expect(page).to have_text("Invalid email or password")
  end

  def then_sign_in_succeeds
    expect(page).to have_text("Your applications")
  end

  def when_i_sign_out
    signout
  end

  def then_i_am_prompted_for_a_2fa_code
    expect(page).to have_text("Use the app on your phone to get your 6-digit 2FA code")
  end

  def when_i_complete_2fa(user)
    complete_2fa_step(user)
  end

  def and_user_account_is_locked
    user.reload
    expect(user.access_locked?).to be true
  end

  def and_user_account_is_unlocked
    user.reload
    expect(user.access_locked?).to be false
  end

  def and_account_locked_email_is_received
    expect(last_email.to[0]).to eql user.email
    expect(last_email.subject).to match(/Your .* Signon development account has been locked/)
  end

  def when_i_visit_edit_user_page(user)
    visit edit_user_path(user)
    expect(page).to have_text("Edit #{user.name}")
  end

  def and_i_unlock_user
    click_button "Unlock account"
  end

  def then_i_see_an_unlock_success_message
    expect(page).to have_text("Unlocked #{user.email}")
  end
end
