require "rails_helper"

RSpec.describe "/users/:user_id/applications/:application_id/permissions", type: :request do
  let(:user) { create(:user) }
  let(:application) { create(:oauth_application) }

  describe "GET /edit" do
    context "when user is not authenticated" do
      it "redirects user to sign in" do
        get edit_user_application_permissions_path(user, application)

        assert_not_authenticated
      end
    end

    context "when user is a normal user" do
      before do
        user.grant_application_signin_permission(application)
        sign_in user
      end

      after do
        sign_out user
      end

      it "does not allow access" do
        get edit_user_application_permissions_path(user, application)

        assert_not_authorised
      end
    end

    context "when user is an admin user" do
      before do
        user.update!(role: "admin")
        user.grant_application_signin_permission(application)
        sign_in user
      end

      after do
        sign_out user
      end

      it "displays user application permissions form" do
        get edit_user_application_permissions_path(user, application)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(CGI.escapeHTML("Update #{user.name}'s permissions for #{application.name}"))
      end

      it "sets not found status code if user does not exist" do
        get edit_user_application_permissions_path({ user_id: "non-existent-user-id" }, application)

        expect(response).to have_http_status(:not_found)
      end

      it "sets not found status code if application does not exist" do
        get edit_user_application_permissions_path(user, { application_id: "non-existent-application-id" })

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "PUT /update" do
    context "when user is not authenticated" do
      it "redirects user to sign in" do
        put user_application_permissions_path(user, application)

        assert_not_authenticated
      end
    end

    context "when user is a normal user" do
      before do
        user.grant_application_signin_permission(application)
        sign_in user
      end

      after do
        sign_out user
      end

      it "does not allow access" do
        put user_application_permissions_path(user, application)

        assert_not_authorised
      end
    end

    context "when user is an admin user" do
      before do
        user.update!(role: "admin")
        user.grant_application_signin_permission(application)
        sign_in user
      end

      after do
        sign_out user
      end

      it "updates permissions" do
        put user_application_permissions_path(user, application), params: { application: { permission_ids: [] } }

        expect(response).to redirect_to(user_applications_path(user))
        follow_redirect!

        expect(response.body).to include("Permissions successfully updated")
      end

      it "sets not found status code if user does not exist" do
        put user_application_permissions_path({ user_id: "non-existent-user-id" }, application)

        expect(response).to have_http_status(:not_found)
      end

      it "sets not found status code if application does not exist" do
        put user_application_permissions_path(user, { application_id: "non-existent-application-id" })

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
