require "rails_helper"

RSpec.describe "API User applications", type: :request do
  let(:user) { create(:user) }
  let(:api_user) { create(:api_user) }

  describe "GET index" do
    context "when user is not authenticated" do
      it "redirects user to sign in" do
        get api_user_applications_path(api_user)

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
        get api_user_applications_path(api_user)

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

      it "displays list of applications api user has access to" do
        application = create(:oauth_application, name: "app-name")
        create(:oauth_access_token, application:, resource_owner_id: api_user.id)

        get api_user_applications_path(api_user)

        expect(response).to have_http_status(:ok)
        assert_select "table:has( > caption[text()='Apps #{api_user.name} has access to'])" do
          assert_select "tr td", text: /app-name/
        end
      end

      it "does not display applications api user where the access token has been revoked" do
        application = create(:oauth_application, name: "revoked-app-name")
        create(:oauth_access_token, application:, resource_owner_id: api_user.id, revoked_at: Time.current)

        get api_user_applications_path(api_user)

        expect(response).to have_http_status(:ok)
        assert_select "tr td", text: /revoked-app-name/, count: 0
      end

      it "displays a link to edit permissions" do
        application = create(:oauth_application, name: "app-name", with_permissions: %w[foo])
        create(:oauth_access_token, application:, resource_owner_id: api_user.id)

        get api_user_applications_path(api_user)

        assert_select "a[href='#{edit_api_user_application_permissions_path(api_user, application)}']", text: "Update permissions for app-name"
      end

      it "does not display a link to edit permissions if the app only has the signin permission" do
        application = create(:oauth_application, name: "app-name")
        create(:oauth_access_token, application:, resource_owner_id: api_user.id)

        get api_user_applications_path(api_user)

        assert_select "a[href='#{edit_api_user_application_permissions_path(api_user, application)}']", count: 0
      end

      it "sets not found status code if user does not exist" do
        get api_user_applications_path({ api_user_id: "non-existent-api-user-id" })

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
