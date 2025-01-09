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

  describe "POST create" do
    context "when user is not authenticated" do
      it "redirects user to sign in" do
        application = create(:oauth_application)

        post oauth_application_permissions_path(application)

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

        post oauth_application_permissions_path(application)

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
        application = create(:oauth_application)

        post oauth_application_permissions_path(application), params: { permission: { name: "admin" } }

        expect(response).to redirect_to(oauth_application_permissions_path(application))
        follow_redirect!

        expect(response.body).to include("Successfully added permission admin to #{application.name}")
      end

      it "creates permission" do
        application = create(:oauth_application)

        expect {
          post oauth_application_permissions_path(application), params: { permission: { name: "admin" } }
        }.to change(Permission, :count).by(1)
      end

      it "displays error and does not create permission if name is not provided" do
        application = create(:oauth_application)

        post oauth_application_permissions_path(application), params: { permission: { name: "" } }
        expect(response.body).to include("Name can't be blank")

        expect(application.reload.permissions).to contain_exactly(application.signin_permission)
      end

      it "displays error and does not create permission if permission already exists" do
        application = create(:oauth_application)

        post oauth_application_permissions_path(application), params: { permission: { name: "signin" } }
        expect(response.body).to include("Name has already been taken")

        expect(application.reload.permissions).to contain_exactly(application.signin_permission)
      end

      it "sets not found status code if the application does not exist" do
        post oauth_application_permissions_path({ oauth_application_id: "non-existent-application-id" }), params: { permission: { name: "admin" } }

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

  describe "GET edit" do
    context "when user is not authenticated" do
      it "redirects user to sign in" do
        application = create(:oauth_application)
        permission = create(:permission, oauth_application: application)

        get edit_oauth_application_permission_path(application, permission)

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
        permission = create(:permission, oauth_application: application)

        get edit_oauth_application_permission_path(application, permission)

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

      it "renders a form for editing existing permission" do
        application = create(:oauth_application)
        permission = create(:permission, oauth_application: application)

        get edit_oauth_application_permission_path(application, permission)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(CGI.escapeHTML("Edit '#{permission.name}' permission for #{application.name}"))
        assert_select "input[name='permission[name]'][value='#{permission.name}']", true
      end

      it "sets not found status code if the application does not exist" do
        permission = create(:permission, oauth_application: create(:oauth_application))
        get new_oauth_application_permission_path({ oauth_application_id: "non-existent-application-id" }, permission)

        expect(response).to have_http_status(:not_found)
      end

      it "sets not found status code if the permission does not exist" do
        application = create(:oauth_application)

        get edit_oauth_application_permission_path(application, { id: "non-existent-permission-id" })

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "PATCH update" do
    context "when user is not authenticated" do
      it "redirects user to sign in" do
        application = create(:oauth_application)
        permission = create(:permission, oauth_application: application)

        patch oauth_application_permission_path(application, permission)

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
        permission = create(:permission, oauth_application: application)

        patch oauth_application_permission_path(application, permission)

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
        application = create(:oauth_application)
        permission = create(:permission, oauth_application: application)

        patch oauth_application_permission_path(application, permission), params: { permission: { name: "admin" } }

        expect(response).to redirect_to(oauth_application_permissions_path(application))
        follow_redirect!

        expect(response.body).to include("Successfully updated permission admin")
      end

      it "updates permission" do
        application = create(:oauth_application)
        permission = create(:permission, oauth_application: application)

        patch oauth_application_permission_path(application, permission), params: { permission: { name: "admin" } }

        expect(permission.reload.name).to eql("admin")
      end

      it "displays error and does not update permission if name is not provided" do
        application = create(:oauth_application)
        permission = create(:permission, oauth_application: application, name: "admin")

        patch oauth_application_permission_path(application, permission), params: { permission: { name: "" } }

        expect(response.body).to include("Name can't be blank")

        expect(permission.reload.name).to eql("admin")
      end

      it "displays error and does not update permission when updating conflicts with an existing permission" do
        application = create(:oauth_application)
        create(:permission, oauth_application: application, name: "admin")
        permission_write = create(:permission, oauth_application: application, name: "write")

        patch oauth_application_permission_path(application, permission_write), params: { permission: { name: "admin" } }
        expect(response.body).to include("Name has already been taken")

        expect(permission_write.reload.name).to eql "write"
      end

      it "prevents updating signin permission" do
        application = create(:oauth_application)

        patch oauth_application_permission_path(application, application.signin_permission), params: { permission: { name: "admin" } }

        expect(response.body).to include("Name of permission signin can't be changed")

        expect(application.signin_permission.reload.name).to eql("signin")
      end

      it "sets not found status code if the application does not exist" do
        application = create(:oauth_application)
        permission = create(:permission, oauth_application: application)

        patch oauth_application_permission_path({ oauth_application_id: "non-existent-application-id" }, permission),
              params: { permission: { name: "admin" } }

        expect(response).to have_http_status(:not_found)
      end

      it "sets not found status code if the permission does not exist" do
        application = create(:oauth_application)

        patch oauth_application_permission_path(application, { id: "non-existent-permission-id" }), params: { permission: { name: "admin" } }

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
