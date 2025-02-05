require "rails_helper"

RSpec.describe "/api_users", type: :request do
  let(:user) { create(:user) }

  describe "GET /index" do
    context "when user is not authenticated" do
      it "redirects user to sign in" do
        get api_users_path

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
        get api_users_path

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

      it "renders list of api users" do
        create(:api_user, email: "api_user@email.com")
        get api_users_path
        assert_select "table tr td:nth-child(1)", /api_user@email.com/
      end

      it "does not list web users" do
        get api_users_path
        assert_select "tr td:nth-child(1)", count: 0, text: /#{user.email}/
      end

      it "renders link to create new api user" do
        get api_users_path

        expect(response).to have_http_status(:ok)
        assert_select "a[href='#{new_api_user_path}']", text: "Create API user"
      end

      it "lists applications for api user" do
        application = create(:oauth_application, name: "app-name")
        api_user = create(:api_user, with_signin_permissions_for: [application])
        create(:oauth_access_token, resource_owner_id: api_user.id, application:)

        get api_users_path

        assert_select "tr td ul>li", text: "app-name"
      end

      it "lists api-only applications for api user" do
        application = create(:oauth_application, name: "app-name", api_only: true)
        api_user = create(:api_user, with_signin_permissions_for: [application])
        create(:oauth_access_token, resource_owner_id: api_user.id, application:)

        get api_users_path

        assert_select "tr td ul>li", text: "app-name"
      end

      it "does not list retired applications for api user" do
        application = create(:oauth_application, name: "app-name", retired: true)
        api_user = create(:api_user, with_signin_permissions_for: [application])
        create(:oauth_access_token, resource_owner_id: api_user.id, application:)

        get api_users_path

        assert_select "tr td ul>li", count: 0, text: "app-name"
      end

      context "when filtering" do
        it "filters by partially matching name" do
          create(:api_user, name: "does-match1")
          create(:api_user, name: "does-match2")
          create(:api_user, name: "does-not-match")

          get api_users_path, params: { name: "does-match" }

          assert_select "table tr td:nth-child(1)", text: /does-match/, count: 2
          assert_select "table tr td:nth-child(1)", text: /does-not-match/, count: 0
        end

        it "filters by partially matching email" do
          create(:api_user, email: "does-match1@email.com")
          create(:api_user, email: "does-match2@email.com")
          create(:api_user, email: "does-not-match@email.com")

          get api_users_path, params: { name: "does-match" }

          assert_select "table tr td:nth-child(1)", text: /does-match/, count: 2
          assert_select "table tr td:nth-child(1)", text: /does-not-match/, count: 0
        end

        it "displays link to clear all filters" do
          get api_users_path
          assert_select "a", text: "Clear all filters", href: api_users_path
        end
      end
    end
  end

  describe "GET /edit" do
    context "when user is not authenticated" do
      it "redirects user to sign in" do
        api_user = create(:api_user)

        get edit_api_user_path(api_user)

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
        api_user = create(:api_user)

        get edit_api_user_path(api_user)

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

      it "renders a form for editing existing api user" do
        api_user = create(:api_user)

        get edit_api_user_path(api_user)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Edit #{api_user.name}")
        assert_select "input[name='api_user[email]']"
        assert_select "input[name='api_user[name]']"
      end

      it "renders a link to suspend api user" do
        api_user = create(:api_user)

        get edit_api_user_path(api_user)

        assert_select "a[href='#{edit_user_suspensions_path(api_user)}']", text: "Suspend user"
      end

      it "renders a link to unsuspend suspended api user" do
        suspended_api_user = create(:api_user, suspended_at: Time.current, reason_for_suspension: "Testing")

        get edit_api_user_path(suspended_api_user)

        assert_select "a[href='#{edit_user_suspensions_path(suspended_api_user)}']", text: "Unsuspend user"
      end

      it "renders a link to manage permissions" do
        api_user = create(:api_user)

        get edit_api_user_path(api_user)

        assert_select "a[href='#{api_user_applications_path(api_user)}']", text: "Manage permissions"
      end

      it "renders a link to manage tokens" do
        api_user = create(:api_user)

        get edit_api_user_path(api_user)

        assert_select "a[href='#{manage_tokens_api_user_path(api_user)}']", text: "Manage tokens"
      end

      it "sets not found status code if the api user does not exist" do
        get edit_api_user_path({ id: "non-existent-user-id" })

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "PATCH /update" do
    context "when user is not authenticated" do
      it "redirects user to sign in" do
        api_user = create(:api_user)

        patch api_user_path(api_user)

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
        api_user = create(:api_user)

        patch api_user_path(api_user)

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
        api_user = create(:api_user)

        patch api_user_path(api_user), params: {
          api_user: {
            name: "Content Store Application",
            email: "content.store@publishing-platform.co.uk",
          },
        }

        expect(response).to redirect_to(api_users_path)
        follow_redirect!

        expect(response.body).to include("Updated user #{api_user.reload.email} successfully")
      end

      it "updates api user" do
        api_user = create(:api_user)

        patch api_user_path(api_user), params: {
          api_user: {
            name: "Content Store Application",
            email: "content.store@publishing-platform.co.uk",
          },
        }

        expect(api_user.reload.name).to eql("Content Store Application")
        expect(api_user.email).to eql("content.store@publishing-platform.co.uk")
      end

      it "does not cause an invitation email to be sent" do
        api_user = create(:api_user)

        patch api_user_path(api_user), params: {
          api_user: {
            name: "Content Store Application",
            email: "content.store@publishing-platform.co.uk",
          },
        }

        emails_received = all_emails.count { |email| email.subject == "Invitation instructions" }
        expect(emails_received).to be 0
      end

      it "displays error and does not update api user if name is not provided" do
        api_user = create(:api_user, name: "An API user")

        patch api_user_path(api_user), params: {
          api_user: {
            name: "",
            email: "content.store@publishing-platform.co.uk",
          },
        }

        expect(response.body).to include("Name can't be blank")

        expect(api_user.reload.name).to eql("An API user")
      end

      it "displays error and does not update user if email is not provided" do
        api_user = create(:api_user, email: "an-api@publishing-platform-co.uk")

        patch api_user_path(api_user), params: {
          api_user: {
            name: "Content Store Application",
            email: "",
          },
        }

        expect(response.body).to include("Email can't be blank")

        expect(api_user.reload.email).to eql("an-api@publishing-platform-co.uk")
      end

      it "sets not found status code if the user does not exist" do
        patch api_user_path({ id: "non-existent-user-id" })

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "GET /new" do
    context "when user is not authenticated" do
      it "redirects user to sign in" do
        get new_api_user_path

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
        get new_api_user_path

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

      it "renders a form for editing existing api user" do
        get new_api_user_path

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Create new API user")
        assert_select "input[name='api_user[email]']"
        assert_select "input[name='api_user[name]']"
      end
    end
  end

  describe "POST /create" do
    context "when user is not authenticated" do
      it "redirects user to sign in" do
        post api_users_path

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
        post api_users_path

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
        post api_users_path, params: {
          api_user: {
            name: "Content Store Application",
            email: "content.store@publishing-platform.co.uk",
          },
        }

        expect(response).to redirect_to(edit_api_user_path(ApiUser.last))
        follow_redirect!

        expect(response.body).to include("Successfully created API user")
      end

      it "creates api user" do
        expect {
          post api_users_path, params: {
            api_user: {
              name: "Content Store Application",
              email: "content.store@publishing-platform.co.uk",
            },
          }
        }.to change(ApiUser, :count).by(1)
      end

      it "does not cause an invitation email to be sent" do
        post api_users_path, params: {
          api_user: {
            name: "Content Store Application",
            email: "content.store@publishing-platform.co.uk",
          },
        }

        emails_received = all_emails.count { |email| email.subject == "Invitation instructions" }
        expect(emails_received).to be 0
      end

      it "displays error and does not create api user if name is not provided" do
        post api_users_path, params: {
          api_user: {
            name: "",
            email: "content.store@publishing-platform.co.uk",
          },
        }

        expect(response.body).to include("Name can't be blank")
        expect(ApiUser.count).to be(0)
      end

      it "displays error and does not update user if email is not provided" do
        post api_users_path, params: {
          api_user: {
            name: "Content Store Application",
            email: "",
          },
        }

        expect(response.body).to include("Email can't be blank")
        expect(ApiUser.count).to be(0)
      end
    end
  end

  describe "GET /manage_tokens" do
    context "when user is not authenticated" do
      it "redirects user to sign in" do
        api_user = create(:api_user)

        get manage_tokens_api_user_path(api_user)

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
        api_user = create(:api_user)

        get manage_tokens_api_user_path(api_user)

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

      it "renders list of api user's access tokens" do
        application = create(:oauth_application, name: "app-name")
        api_user = create(:api_user, with_signin_permissions_for: [application])
        token = create(:oauth_access_token, resource_owner_id: api_user.id, application:)

        get manage_tokens_api_user_path(api_user)

        assert_select "table tr td:nth-child(2)", /^#{token[0..7]}/
      end

      it "renders links to revoke tokens" do
        application = create(:oauth_application, name: "app-name")
        api_user = create(:api_user, with_signin_permissions_for: [application])
        token = create(:oauth_access_token, resource_owner_id: api_user.id, application:)

        get manage_tokens_api_user_path(api_user)

        assert_select "table tr td:nth-child(5) a[href='#{edit_api_user_authorisation_path(api_user, token)}']", /Revoke/
      end

      it "renders link to add application token" do
        api_user = create(:api_user)

        get manage_tokens_api_user_path(api_user)

        expect(response).to have_http_status(:ok)
        assert_select "a[href='#{new_api_user_authorisation_path(api_user)}']", text: "Add application token"
      end

      it "does not list revoked tokens" do
        application = create(:oauth_application, name: "app-name")
        api_user = create(:api_user, with_signin_permissions_for: [application])
        create(:oauth_access_token, resource_owner_id: api_user.id, application:, revoked_at: Time.current)

        get manage_tokens_api_user_path(api_user)

        assert_select "table tbody tr", count: 0
      end

      it "sets not found status code if the user does not exist" do
        get manage_tokens_api_user_path({ id: "non-existent-user-id" })

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
