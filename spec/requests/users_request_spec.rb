require "rails_helper"

RSpec.describe "Users", type: :request do
  let(:user) { create(:user) }

  describe "GET index" do
    context "when user is not authenticated" do
      it "redirects user to sign in" do
        get users_path

        assert_not_authenticated
      end
    end

    context "when user is a normal user" do
      before do
        sign_in user
      end

      after do
        sign_out user
      end

      it "does not allow access" do
        get users_path

        assert_not_authorised
      end
    end

    context "when user is an admin user" do
      before do
        user.update!(role: "admin", name: "admin@email.com")
        sign_in user
      end

      after do
        sign_out user
      end

      it "renders list of users" do
        create(:user, email: "another_user@email.com")
        get users_path
        assert_select "table tr td:nth-child(1)", /another_user@email.com/
      end

      it "does not list api users" do
        create(:api_user, email: "api_user@email.com")
        get users_path
        assert_select "tr td:nth-child(1)", count: 0, text: /api_user@email.com/
      end

      it "renders link to invite new user" do
        get users_path

        expect(response).to have_http_status(:ok)
        assert_select "a[href='#{new_user_invitation_path}']", text: "Create user"
      end

      context "when filtering" do
        it "filters by partially matching name" do
          create(:user, name: "does-match1")
          create(:user, name: "does-match2")
          create(:user, name: "does-not-match")

          get users_path, params: { name: "does-match" }

          assert_select "table tr td:nth-child(1)", text: /does-match/, count: 2
          assert_select "table tr td:nth-child(1)", text: /does-not-match/, count: 0
        end

        it "filters by partially matching email" do
          create(:user, email: "does-match1@email.com")
          create(:user, email: "does-match2@email.com")
          create(:user, email: "does-not-match@email.com")

          get users_path, params: { name: "does-match" }

          assert_select "table tr td:nth-child(1)", text: /does-match/, count: 2
          assert_select "table tr td:nth-child(1)", text: /does-not-match/, count: 0
        end

        it "filters by role" do
          create(:user, name: "normal-user")
          create(:admin_user, name: "admin-user")

          get users_path, params: { role: "normal" }

          assert_select "table tr td:nth-child(1)", text: /admin-user/, count: 0
          assert_select "table tr td:nth-child(1)", text: /normal-user/

          get users_path, params: { role: "admin" }

          assert_select "table tr td:nth-child(1)", text: /admin-user/
          assert_select "table tr td:nth-child(1)", text: /normal-user/, count: 0
        end

        it "filters by status" do
          create(:active_user, name: "active-user")
          create(:suspended_user, name: "suspended-user")
          create(:invited_user, name: "invited-user")
          create(:locked_user, name: "locked-user")

          get users_path, params: { status: "locked" }

          assert_select "tr td:nth-child(1)", text: /active-user/, count: 0
          assert_select "tr td:nth-child(1)", text: /suspended-user/, count: 0
          assert_select "tr td:nth-child(1)", text: /invited-user/, count: 0
          assert_select "tr td:nth-child(1)", text: /locked-user/

          get users_path, params: { status: "suspended" }

          assert_select "tr td:nth-child(1)", text: /active-user/, count: 0
          assert_select "tr td:nth-child(1)", text: /suspended-user/
          assert_select "tr td:nth-child(1)", text: /invited-user/, count: 0
          assert_select "tr td:nth-child(1)", text: /locked-user/, count: 0
        end

        it "filters by organisation" do
          organisation1 = create(:organisation, name: "Organisation 1")
          organisation2 = create(:organisation, name: "Organisation 2")
          organisation3 = create(:organisation, name: "Organisation 3")

          create(:user, name: "user1-in-organisation1", organisation: organisation1)
          create(:user, name: "user2-in-organisation1", organisation: organisation1)
          create(:user, name: "user3-in-organisation2", organisation: organisation2)
          create(:user, name: "user4-in-organisation3", organisation: organisation3)

          get users_path, params: { organisation: organisation1.id }

          assert_select "tr td:nth-child(1)", text: /user1-in-organisation1/
          assert_select "tr td:nth-child(1)", text: /user2-in-organisation1/
          assert_select "tr td:nth-child(1)", text: /user3-in-organisation2/, count: 0
          assert_select "tr td:nth-child(1)", text: /user4-in-organisation3/, count: 0
        end

        it "displays link to clear all filters" do
          get users_path
          assert_select "a", text: "Clear all filters", href: users_path
        end
      end
    end
  end

  describe "GET edit" do
    context "when user is not authenticated" do
      it "redirects user to sign in" do
        another_user = create(:user)

        get edit_user_path(another_user)

        assert_not_authenticated
      end
    end

    context "when user is a normal user" do
      before do
        sign_in user
      end

      after do
        sign_out user
      end

      it "does not allow access" do
        another_user = create(:user)

        get edit_user_path(another_user)

        assert_not_authorised
      end
    end

    context "when user is an admin user" do
      before do
        user.update!(role: "admin")
        sign_in user
      end

      after do
        sign_out user
      end

      it "renders a form for editing existing user" do
        another_user = create(:user)

        get edit_user_path(another_user)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Edit #{another_user.name}")
        assert_select "input[name='user[email]']"
        assert_select "input[name='user[name]']"
        assert_select "select[name='user[role]']"
        assert_select "select[name='user[organisation_id]']"
      end

      it "renders a link to suspend user" do
        another_user = create(:user)

        get edit_user_path(another_user)

        assert_select "a[href='#{edit_user_suspensions_path(another_user)}']", text: "Suspend user"
      end

      it "renders a link to unsuspend suspended user" do
        suspended_user = create(:suspended_user)

        get edit_user_path(suspended_user)

        assert_select "a[href='#{edit_user_suspensions_path(suspended_user)}']", text: "Unsuspend user"
      end

      it "renders a form to resend invitation for a user who has been invited but has not accepted" do
        invited_user = create(:invited_user)

        get edit_user_path(invited_user)

        assert_select "form[action='#{resend_user_invitation_path(invited_user)}'] input[type='submit'][value='Resend signup email']"
      end

      it "renders a form to unlock account for a user who has been locked out" do
        locked_user = create(:locked_user)

        get edit_user_path(locked_user)

        assert_select "form[action='#{unlock_user_path(locked_user)}'] input[type='submit'][value='Unlock account']"
      end

      it "renders a form to resend confirmation email for a user who has a pending email change" do
        another_user = create(:user, unconfirmed_email: "unconfirmed@email.com")

        get edit_user_path(another_user)

        assert_select "form[action='#{resend_email_change_user_path(another_user)}'] input[type='submit'][value='Resend confirmation email']"
      end

      it "renders a form to cancel email change for a user who has a pending email change" do
        another_user = create(:user, unconfirmed_email: "unconfirmed@email.com")

        get edit_user_path(another_user)

        assert_select "form[action='#{cancel_email_change_user_path(another_user)}'] input[type='submit'][value='Cancel email change']"
      end

      it "renders a form to reset 2FA" do
        another_user = create(:user, otp_secret: "secret")

        get edit_user_path(another_user)

        assert_select "form[action='#{reset_2fa_user_path(another_user)}'] input[type='submit'][value='Reset 2FA']"
      end

      it "sets not found status code if the user does not exist" do
        get edit_user_path({ id: "non-existent-user-id" })

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "PATCH update" do
    context "when user is not authenticated" do
      it "redirects user to sign in" do
        another_user = create(:user)

        patch user_path(another_user)

        assert_not_authenticated
      end
    end

    context "when user is a normal user" do
      before do
        sign_in user
      end

      after do
        sign_out user
      end

      it "does not allow access" do
        another_user = create(:user)

        patch user_path(another_user)

        assert_not_authorised
      end
    end

    context "when user is an admin user" do
      before do
        user.update!(role: "admin")
        sign_in user
      end

      after do
        sign_out user
      end

      it "redirects and displays success message" do
        another_user = create(:user)

        patch user_path(another_user), params: { user: { name: "Joe Bloggs" } }

        expect(response).to redirect_to(users_path)
        follow_redirect!

        expect(response.body).to include("Updated user #{another_user.email} successfully")
      end

      it "updates user" do
        another_user = create(:user)

        patch user_path(another_user), params: { user: { name: "Joe Bloggs" } }

        expect(another_user.reload.name).to eql("Joe Bloggs")
      end

      it "causes new invitation email to be sent if email is updated and user is invited but has not yet accepted" do
        invited_user = create(:invited_user)
        new_email = "joe@email.com"

        patch user_path(invited_user), params: { user: { email: new_email } }

        expect(invited_user.reload.email).to eql(new_email)
        expect(last_email.to).to contain_exactly(new_email)
        expect(last_email.subject).to eql "Invitation instructions"
      end

      it "displays error and does not update user if name is not provided" do
        another_user = create(:user, name: "Joe Bloggs")

        patch user_path(another_user), params: { user: { name: "" } }

        expect(response.body).to include("Name can't be blank")

        expect(another_user.reload.name).to eql("Joe Bloggs")
      end

      it "displays error and does not update user if email is not provided" do
        another_user = create(:user, email: "joe@email.com")

        patch user_path(another_user), params: { user: { email: "" } }

        expect(response.body).to include("Email can't be blank")

        expect(another_user.reload.email).to eql("joe@email.com")
      end

      it "displays error and does not update user if role is not provided" do
        another_user = create(:user, email: "joe@email.com")

        patch user_path(another_user), params: { user: { role: "" } }

        expect(response.body).to include("Role is not included in the list")

        expect(another_user.reload.role).to eql("normal")
      end

      it "sets not found status code if the user does not exist" do
        patch user_path(user, { id: "non-existent-user-id" })

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "GET edit_email_or_password" do
    context "when user is not authenticated" do
      it "redirects user to sign in" do
        get edit_email_or_password_user_path(user)

        assert_not_authenticated
      end
    end

    context "when user is authenticated" do
      before do
        sign_in user
      end

      after do
        sign_out user
      end

      it "does not allow access to edit another user's email or password" do
        another_user = create(:user)

        get edit_email_or_password_user_path(another_user)

        assert_not_authorised
      end

      it "renders a form for editing user's own email" do
        get edit_email_or_password_user_path(user)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Edit your account")

        assert_select "form[action='#{update_email_user_path(user)}'] input[name='user[email]']"
      end

      it "renders a form for editing user's own password" do
        get edit_email_or_password_user_path(user)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Edit your account")

        assert_select "form[action='#{update_password_user_path(user)}']" do
          assert_select "input[name='user[password]'][type='password']"
          assert_select "input[name='user[password_confirmation]'][type='password']"
        end
      end

      context "and they have a pending email change" do
        before do
          user.update!(unconfirmed_email: "unconfirmed@email.com")
        end

        it "renders a form to resend confirmation email for a user who has a pending email change" do
          get edit_email_or_password_user_path(user)

          assert_select "form[action='#{resend_email_change_user_path(user)}'] input[type='submit'][value='Resend confirmation email']"
        end

        it "renders a form to cancel email change for a user who has a pending email change" do
          get edit_email_or_password_user_path(user)

          assert_select "form[action='#{cancel_email_change_user_path(user)}'] input[type='submit'][value='Cancel email change']"
        end
      end

      it "sets not found status code if the user does not exist" do
        get edit_email_or_password_user_path({ id: "non-existent-user-id" })

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "PATCH update_email" do
    context "when user is not authenticated" do
      it "redirects user to sign in" do
        patch update_email_user_path(user)

        assert_not_authenticated
      end
    end

    context "when user is authenticated" do
      before do
        sign_in user
      end

      after do
        sign_out user
      end

      it "updates user, sends confirmation email to new address and email change notification to old address" do
        perform_enqueued_jobs do
          old_email = user.email

          patch update_email_user_path(user), params: { user: { email: "new@email.com" } }

          user.reload

          expect(user.unconfirmed_email).to eql("new@email.com")
          expect(user.email).to eql(old_email)

          confirmation_email = all_emails[-2]

          expect(confirmation_email.subject).to eql("Confirm your email change")
          expect(confirmation_email.to.first).to eql("new@email.com")

          email_changed_email = all_emails[-1]

          expect(email_changed_email.subject).to eql("Your Publishing Platform Signon development email address is being changed")
          expect(email_changed_email.to.first).to eql(old_email)
        end
      end

      it "redirects and displays success message" do
        patch update_email_user_path(user), params: { user: { email: "new@email.com" } }

        expect(response).to redirect_to(root_path)
        follow_redirect!

        expect(response.body).to include("An email has been sent to new@email.com. Follow the link in the email to update your address.")
      end

      it "does nothing if new email address is same as old address" do
        patch update_email_user_path(user), params: { user: { email: user.email } }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Nothing to update.")
      end

      it "displays error and does not update user if email is not provided" do
        old_email = user.email

        patch update_email_user_path(user), params: { user: { email: "" } }

        expect(response).to have_http_status(:ok)

        expect(response.body).to include("Email can't be blank")

        expect(user.reload.email).to eql(old_email)
      end

      it "displays error and does not update user if email provided is invalid" do
        old_email = user.email

        patch update_email_user_path(user), params: { user: { email: "invalid-email" } }

        expect(response).to have_http_status(:ok)

        expect(response.body).to include("Email is invalid")

        expect(user.reload.email).to eql(old_email)
      end

      it "sets not found status code if the user does not exist" do
        patch update_email_user_path({ id: "non-existent-user-id" })

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "PATCH update_password" do
    context "when user is not authenticated" do
      it "redirects user to sign in" do
        patch update_password_user_path(user)

        assert_not_authenticated
      end
    end

    context "when user is authenticated" do
      let(:original_password) { "bf3b2cc3bb659ad6e740533b06c0b899" }
      let(:new_password) { "0871feaffef29223358cbf086b4084c4" }
      let(:user) { create(:user, password: original_password) }

      before do
        sign_in user
      end

      after do
        sign_out user
      end

      it "update password if password is sufficiently strong" do
        patch update_password_user_path(user), params: { user: {
          current_password: original_password,
          password: new_password,
          password_confirmation: new_password,
        } }

        expect(user.reload.valid_password?(new_password)).to be true

        expect(response).to redirect_to(root_path)
        follow_redirect!

        expect(response.body).to include("Your password has been changed successfully. You are now signed in.")
      end

      it "displays error and does not update password if password is too short" do
        new_password = "5ef48BE84"

        patch update_password_user_path(user), params: { user: {
          current_password: original_password,
          password: new_password,
          password_confirmation: new_password,
        } }

        expect(user.reload.valid_password?(original_password)).to be true

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Password is too short (minimum is 10 characters)")
      end

      it "displays error and does not update password if current password is blank" do
        patch update_password_user_path(user), params: { user: {
          current_password: "",
          password: new_password,
          password_confirmation: new_password,
        } }

        expect(user.reload.valid_password?(original_password)).to be true

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Current password can't be blank")
      end

      it "displays error and does not update password if password confirmation does not match password" do
        patch update_password_user_path(user), params: { user: {
          current_password: original_password,
          password: new_password,
          password_confirmation: "#{new_password}extra",
        } }

        expect(user.reload.valid_password?(original_password)).to be true

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Password confirmation doesn't match Password")
      end

      it "sets not found status code if the user does not exist" do
        patch update_password_user_path({ id: "non-existent-user-id" })

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "PUT resend_email_change" do
    context "when user is not authenticated" do
      it "redirects user to sign in" do
        put resend_email_change_user_path(user)

        assert_not_authenticated
      end
    end

    context "when user is authenticated" do
      let(:user) { create(:user_with_pending_email_change) }

      before do
        sign_in user
      end

      after do
        sign_out user
      end

      context "and is a normal user" do
        context "and is resending for own account" do
          it "sends an email change confirmation email" do
            put resend_email_change_user_path(user)

            expect(last_email.subject).to eql "Confirm your email change"
          end

          it "redirects and displays success message" do
            put resend_email_change_user_path(user)

            expect(response).to redirect_to(root_path)
            follow_redirect!

            expect(response.body).to include("An email has been sent to #{user.unconfirmed_email}. Follow the link in the email to update your address.")
          end
        end

        context "and is resending for another user's account" do
          it "does not allow access" do
            another_user = create(:user)

            put resend_email_change_user_path(another_user)

            assert_not_authorised
          end
        end
      end

      context "and is an admin user" do
        let(:user) { create(:admin_user) }
        let(:another_user) { create(:user_with_pending_email_change) }

        it "sends an email change confirmation email for another user's account" do
          put resend_email_change_user_path(another_user)

          expect(last_email.subject).to eql "Confirm your email change"
        end

        it "redirects and displays success message" do
          put resend_email_change_user_path(another_user)

          expect(response).to redirect_to(root_path)
          follow_redirect!

          expect(response.body).to include("Successfully resent email change email to #{another_user.unconfirmed_email}")
        end

        it "redirects and displays error message if user is not pending email change confirmation" do
          another_user = create(:user)

          put resend_email_change_user_path(another_user)

          expect(response).to redirect_to(edit_user_path(another_user))
          follow_redirect!

          expect(response.body).to include("Failed to send email change email")
        end

        it "redirects and displays error message when there is a model error" do
          another_user.errors.add(:email)
          allow(User).to receive(:find).with(another_user.id.to_s).and_return(another_user)

          put resend_email_change_user_path(another_user)

          expect(response).to redirect_to(edit_user_path(another_user))
          follow_redirect!

          expect(response.body).to include("Failed to send email change email")
        end
      end

      it "sets not found status code if the user does not exist" do
        put resend_email_change_user_path({ id: "non-existent-user-id" })

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "DELETE cancel_email_change" do
    context "when user is not authenticated" do
      it "redirects user to sign in" do
        delete cancel_email_change_user_path(user)

        assert_not_authenticated
      end
    end

    context "when user is authenticated" do
      let(:user) { create(:user_with_pending_email_change) }

      before do
        sign_in user
      end

      after do
        sign_out user
      end

      context "and is a normal user" do
        context "and is resending for own account" do
          it "clears unconfirmed_email & confirmation_token" do
            delete cancel_email_change_user_path(user)

            user.reload
            expect(user.unconfirmed_email.blank?).to be true
            expect(user.confirmation_token.blank?).to be true
          end

          it "redirects to root" do
            delete cancel_email_change_user_path(user)

            expect(response).to redirect_to(root_path)
          end
        end

        context "and is cancelling for another user's account" do
          it "does not allow access" do
            another_user = create(:user_with_pending_email_change, email: "another@email.com")

            delete cancel_email_change_user_path(another_user)

            assert_not_authorised
          end
        end
      end

      context "and is an admin user" do
        let(:user) { create(:admin_user) }
        let(:another_user) { create(:user_with_pending_email_change) }

        it "clears unconfirmed_email & confirmation_token for another user's account" do
          delete cancel_email_change_user_path(another_user)

          another_user.reload
          expect(another_user.unconfirmed_email.blank?).to be true
          expect(another_user.confirmation_token.blank?).to be true
        end

        it "redirects to root" do
          delete cancel_email_change_user_path(another_user)

          expect(response).to redirect_to(root_path)
        end
      end

      it "sets not found status code if the user does not exist" do
        delete cancel_email_change_user_path({ id: "non-existent-user-id" })

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "PATCH reset_2fa" do
    context "when user is not authenticated" do
      it "redirects user to sign in" do
        patch reset_2fa_user_path(user)

        assert_not_authenticated
      end
    end

    context "when user is a normal user" do
      before do
        sign_in user
      end

      after do
        sign_out user
      end

      it "does not allow access" do
        patch reset_2fa_user_path(user)

        assert_not_authorised
      end
    end

    context "when user is an admin user" do
      let(:user) { create(:admin_user) }

      before do
        sign_in user
      end

      after do
        sign_out user
      end

      it "resets 2FA for user" do
        two_factor_user = create(:two_factor_enabled_user)

        patch reset_2fa_user_path(two_factor_user)

        two_factor_user.reload
        expect(two_factor_user.otp_secret.blank?).to be true
        expect(two_factor_user.require_2fa?).to be true
      end

      # it "redirects to root" do
      #   delete cancel_email_change_user_path(another_user)

      #   expect(response).to redirect_to(root_path)
      # end

      it "redirects and displays success message" do
        two_factor_user = create(:two_factor_enabled_user)

        patch reset_2fa_user_path(two_factor_user)

        expect(response).to redirect_to(root_path)
        follow_redirect!

        expect(response.body).to include("Reset 2-Factor Authentication (2FA) for #{two_factor_user.email}")
      end

      it "sends email notifying user that their 2FA has been reset" do
        two_factor_user = create(:two_factor_enabled_user)

        perform_enqueued_jobs do
          patch reset_2fa_user_path(two_factor_user)
        end

        email = last_email
        expect(email.present?).to be true
        expect(email.subject).to eql "2-Factor Authentication (2FA) has been reset"
      end

      it "sets not found status code if the user does not exist" do
        patch reset_2fa_user_path({ id: "non-existent-user-id" })

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
