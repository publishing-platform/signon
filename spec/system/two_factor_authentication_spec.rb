require "rails_helper"

RSpec.describe "Two Factor Authentication", type: :system do
  let!(:new_secret) { ROTP::Base32.random_base32  }
  let!(:original_secret) { ROTP::Base32.random_base32 }

  context "when setting a 2FA code" do
    before do
      allow(ROTP::Base32).to receive(:random_base32).and_return(new_secret)
    end

    context "and signed in with an existing 2FA setup" do
      let(:user) { create(:user, email: "jane.user@example.com", otp_secret: original_secret) }

      before do
        visit new_user_session_path
        signin_with(user)
        visit two_factor_authentication_path
      end

      it "shows the TOTP secret and a warning" do
        expect(page).to have_text("Enter this code when asked: #{new_secret}")
        expect(page).to have_text("Setting up a new phone will replace your existing one. You will only be able to sign in with your new phone.")
      end

      it "rejects an invalid code" do
        fill_in "code", with: "abcdef"
        click_button "Finish replacing your phone"

        expect(page).to have_text("Sorry, that code didn't work.")
        expect(page).to have_text("Enter this code when asked: #{new_secret}")
      end

      it "accepts a valid code and persists the secret" do
        enter_2fa_code(new_secret)
        click_button "Finish replacing your phone"

        expect(page).to have_text("2-Factor Authentication phone changed successfully")
        expect(user.reload.otp_secret).to eql new_secret
      end

      it "redirects to dashboard on success" do
        enter_2fa_code(new_secret)
        click_button "Finish replacing your phone"

        expect(page).to have_current_path(root_path)
        expect(page).to have_text("2-Factor Authentication phone changed successfully")
      end

      it "requires the code again on next login" do
        enter_2fa_code(new_secret)
        click_button "Finish replacing your phone"

        click_link "Sign out"

        signin_with(user, second_step: false)

        expect(page).to have_text("Use the app on your phone to get your 6-digit 2FA code")
      end
    end

    context "and signed in without an existing 2FA setup" do
      let(:user) { create(:user, email: "jane.user@example.com") }

      before do
        visit new_user_session_path
        signin_with(user, set_up_2fa: false)
      end

      context "when visiting the 2FA setup page" do
        before do
          visit two_factor_authentication_path
        end

        it "shows the TOTP secret" do
          expect(page).to have_text("Enter this code when asked: #{new_secret}")
        end

        it "rejects an invalid code" do
          fill_in "code", with: "abcdef"
          click_button "Finish set up"

          expect(page).to have_text("Sorry, that code didn't work.")
          expect(page).to have_text("Enter this code when asked: #{new_secret}")
        end

        it "accepts a valid code and persists the secret" do
          enter_2fa_code(new_secret)
          click_button "Finish set up"

          expect(page).to have_text("2-Factor Authentication set up")
          expect(user.reload.otp_secret).to eql new_secret
        end

        it "requires the code again on next login" do
          enter_2fa_code(new_secret)
          click_button "Finish set up"

          click_link "Sign out"

          signin_with(user, second_step: false)

          expect(page).to have_text("Use the app on your phone to get your 6-digit 2FA code")
        end

        it "accepts a valid code from a device which has a small time lag" do
          old_code = Timecop.freeze(29.seconds.ago) { ROTP::TOTP.new(new_secret).now }

          Timecop.freeze do
            fill_in "code", with: old_code
            click_button "Finish set up"
          end

          expect(page).to have_text("2-Factor Authentication set up")
          expect(user.reload.otp_secret).to eql new_secret
        end
      end

      context "when visiting the 2FA sign-in page" do
        before do
          visit new_two_factor_authentication_session_path
        end

        context "and 2FA is mandated (default)" do
          it "redirects to 2FA setup prompt" do
            expect(page).to have_text("Make your account more secure by setting up 2‑Factor Authentication.")
            expect(page).to have_current_path(prompt_two_factor_authentication_path)
          end
        end

        context "and 2FA is not required" do
          let(:user) { create(:user, email: "jane.user@example.com", require_2fa: false) }

          it "redirects to home page" do
            expect(page).to have_text("Your applications")
            expect(page).to have_current_path(root_path)
          end
        end
      end
    end
  end
end
