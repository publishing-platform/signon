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

      it "sets not found status code if the user does not exist" do
        get edit_user_path(user, { id: "non-existent-user-id" })

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
