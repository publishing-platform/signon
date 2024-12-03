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
        get edit_user_path(user, { id: "non-existent-user-id" })

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
end
