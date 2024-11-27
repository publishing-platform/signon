require "rails_helper"

RSpec.describe "Permissions", type: :request do
  let(:user) { create(:user) }

  describe "GET new" do
    context "when user is not authenticated" do
      it "redirects user to sign in" do
        application = create(:oauth_application)

        get new_oauth_application_permission_path(application)

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
        application = create(:oauth_application)

        get new_oauth_application_permission_path(application)

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

      it "renders a form for creating a new permission" do
        application = create(:oauth_application)

        get new_oauth_application_permission_path(application)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Add permission for #{application.name}")
        assert_select "input[name='permission[name]']", true
      end

      it "sets not found status code if the application does not exist" do
        get new_oauth_application_permission_path({ oauth_application_id: "non-existent-application-id" })

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "GET index" do
    context "when user is not authenticated" do
      it "redirects user to sign in" do
        application = create(:oauth_application)

        get oauth_application_permissions_path(application)

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
        application = create(:oauth_application)

        get oauth_application_permissions_path(application)

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

      it "renders list of permissions" do
        application = create(:oauth_application)
        permission = create(:permission, oauth_application: application)

        get oauth_application_permissions_path(application)

        expect(response).to have_http_status(:ok)
        assert_select "table tr td a[href='#{edit_oauth_application_permission_path(application, permission)}']",
                      text: permission.name
      end

      it "renders link to create permission" do
        application = create(:oauth_application)

        get oauth_application_permissions_path(application)

        expect(response).to have_http_status(:ok)
        assert_select "a[href='#{new_oauth_application_permission_path(application)}']", text: "Add permission"
      end

      it "sets not found status code if the application does not exist" do
        get oauth_application_permissions_path({ oauth_application_id: "non-existent-application-id" })

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
