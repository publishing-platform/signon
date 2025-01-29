require "rails_helper"

RSpec.describe "/users/:user_id/applications/:application_id/signin_permission", type: :request do
  let(:user) { create(:user) }
  let(:application) { create(:oauth_application) }

  describe "POST create" do
    context "when user is not authenticated" do
      it "redirects user to sign in" do
        post user_application_signin_permission_path(user, application)

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
        post user_application_signin_permission_path(user, application)

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

      it "grants user access to application" do
        post user_application_signin_permission_path(user, application)

        expect(response).to redirect_to(user_applications_path(user))
        follow_redirect!

        expect(response.body).to include(delete_user_application_signin_permission_path(user, application))
      end

      it "sets not found status code if user does not exist" do
        post user_application_signin_permission_path({ user_id: "non-existent-user-id" }, application)

        expect(response).to have_http_status(:not_found)
      end

      it "sets not found status code if application does not exist" do
        post user_application_signin_permission_path(user, { application_id: "non-existent-application-id" })

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "GET delete" do
    context "when user is not authenticated" do
      it "redirects user to sign in" do
        get delete_user_application_signin_permission_path(user, application)

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
        get delete_user_application_signin_permission_path(user, application)

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

      it "displays a form allowing user to confirm or cancel removal of access to the application" do
        get delete_user_application_signin_permission_path(user, application)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Are you sure you want to remove #{user.name}'s access to #{application.name}?")
      end

      it "sets not found status code if user does not exist" do
        get delete_user_application_signin_permission_path({ user_id: "non-existent-user-id" }, application)

        expect(response).to have_http_status(:not_found)
      end

      it "sets not found status code if application does not exist" do
        get delete_user_application_signin_permission_path(user, { application_id: "non-existent-application-id" })

        expect(response).to have_http_status(:not_found)
      end

      it "sets not found status code if user does not have signin permission on application" do
        user_without_signin = create(:admin_user)
        get delete_user_application_signin_permission_path(user_without_signin, application)

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "DELETE destroy" do
    context "when user is not authenticated" do
      it "redirects user to sign in" do
        delete user_application_signin_permission_path(user, application)

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
        delete user_application_signin_permission_path(user, application)

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

      it "removes user access to application" do
        delete user_application_signin_permission_path(user, application)

        expect(response).to redirect_to(user_applications_path(user))
        follow_redirect!

        expect(response.body).not_to include(delete_user_application_signin_permission_path(user, application))
      end

      it "sets not found status code if user does not exist" do
        delete user_application_signin_permission_path({ user_id: "non-existent-user-id" }, application)

        expect(response).to have_http_status(:not_found)
      end

      it "sets not found status code if application does not exist" do
        delete user_application_signin_permission_path(user, { application_id: "non-existent-application-id" })

        expect(response).to have_http_status(:not_found)
      end

      it "sets not found status code if user does not have signin permission on application" do
        user_without_signin = create(:admin_user)
        delete user_application_signin_permission_path(user_without_signin, application)

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
