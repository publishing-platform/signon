require "rails_helper"

RSpec.describe "/api_users/:api_user_id/applications/:application_id/permissions", type: :request do
  let(:user) { create(:user) }

  describe "GET /edit" do
    context "when user is not authenticated" do
      it "redirects user to sign in" do
        application = create(:oauth_application)
        api_user = create(:api_user)
        create(:oauth_access_token, application:, resource_owner_id: api_user.id)

        get edit_api_user_application_permissions_path(api_user, application)

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
        api_user = create(:api_user)
        create(:oauth_access_token, application:, resource_owner_id: api_user.id)

        get edit_api_user_application_permissions_path(api_user, application)

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

      it "renders a page with checkboxes for the grantable permissions and a hidden field for the signin permission so that it is not removed" do
        application = create(:oauth_application)
        granted_permission = create(:permission, oauth_application: application)
        grantable_permission = create(:permission, oauth_application: application)
        api_user = create(:api_user, with_permissions: { application => [granted_permission.name] })
        create(:oauth_access_token, application:, resource_owner_id: api_user.id)

        get edit_api_user_application_permissions_path(api_user, application)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(CGI.escapeHTML("Update #{api_user.name}'s permissions for #{application.name}"))

        assert_select "input[type='checkbox'][checked='checked'][name='application[permission_ids][]'][value='#{granted_permission.id}']"
        assert_select "input[type='checkbox'][name='application[permission_ids][]'][value='#{grantable_permission.id}']"
        assert_select "input[type='checkbox'][name='application[permission_ids][]'][value='#{application.signin_permission.id}']", count: 0
        assert_select "input[type='hidden'][value='#{application.signin_permission.id}']"
      end

      it "allows access to users with a revoked access token when there is at least one non-revoked access token" do
        application = create(:oauth_application)
        api_user = create(:api_user)
        create(:oauth_access_token, application:, resource_owner_id: api_user.id, revoked_at: Time.current)
        create(:oauth_access_token, resource_owner_id: api_user.id, application:)

        get edit_api_user_application_permissions_path(api_user, application)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(CGI.escapeHTML("Update #{api_user.name}'s permissions for #{application.name}"))
      end

      it "sets not found status code if the user only has a revoked access token" do
        application = create(:oauth_application)
        api_user = create(:api_user)
        create(:oauth_access_token, application:, resource_owner_id: api_user.id, revoked_at: Time.current)

        get edit_api_user_application_permissions_path(api_user, application)

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "PATCH /update" do
    context "when user is not authenticated" do
      it "redirects user to sign in" do
        application = create(:oauth_application)
        api_user = create(:api_user)
        create(:oauth_access_token, application:, resource_owner_id: api_user.id)

        patch api_user_application_permissions_path(api_user, application)

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
        api_user = create(:api_user)
        create(:oauth_access_token, application:, resource_owner_id: api_user.id)

        patch api_user_application_permissions_path(api_user, application)

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

      it "updates non-signin permissions, retaining the signin permission, then redirects to the API applications path" do
        application = create(:oauth_application)
        granted_permission = create(:permission, oauth_application: application)
        grantable_permission = create(:permission, oauth_application: application)

        api_user = create(:api_user,
                          with_signin_permissions_for: [application],
                          with_permissions: { application => [granted_permission.name] })

        create(:oauth_access_token, application:, resource_owner_id: api_user.id)

        patch api_user_application_permissions_path(api_user, application, params: { application: { permission_ids: [grantable_permission.id] } })

        expect(api_user.permission_ids_for(application)).to contain_exactly(grantable_permission.id, application.signin_permission.id)

        expect(response).to redirect_to(api_user_applications_path(api_user))

        follow_redirect!

        expect(response.body).to include("Permissions successfully updated")
      end

      context "and updating permissions for app A" do
        it "prevents additionally adding or removing permissions for app B" do
          application_a = create(:oauth_application)
          application_a_granted_permission = create(:permission, oauth_application: application_a)
          application_a_grantable_permission = create(:permission, oauth_application: application_a)

          application_b = create(:oauth_application)
          application_b_granted_permission = create(:permission, oauth_application: application_b)
          application_b_grantable_permission = create(:permission, oauth_application: application_b)

          api_user = create(:api_user,
                            with_signin_permissions_for: [application_a, application_b],
                            with_permissions: {
                              application_a => [application_a_granted_permission.name],
                              application_b => [application_b_granted_permission.name],
                            })

          create(:oauth_access_token, application: application_a, resource_owner_id: api_user.id)
          create(:oauth_access_token, application: application_b, resource_owner_id: api_user.id)

          patch api_user_application_permissions_path(api_user,
                                                      application_a,
                                                      params: { application: { permission_ids: [application_a_grantable_permission.id, application_b_grantable_permission.id] } })

          expect(api_user.permissions).to contain_exactly(
            application_a.signin_permission,
            application_a_grantable_permission,
            application_b.signin_permission,
            application_b_granted_permission,
          )
        end
      end

      it "updates permissions when the user has revoked access tokens but there is at least one non-revoked access token" do
        application = create(:oauth_application)
        permission = create(:permission, oauth_application: application)

        api_user = create(:api_user,
                          with_signin_permissions_for: [application])

        create(:oauth_access_token, application:, resource_owner_id: api_user.id, revoked_at: Time.current)
        create(:oauth_access_token, application:, resource_owner_id: api_user.id)

        patch api_user_application_permissions_path(api_user, application, params: { application: { permission_ids: [permission.id] } })

        expect(api_user.permission_ids_for(application)).to contain_exactly(application.signin_permission.id, permission.id)

        expect(response).to redirect_to(api_user_applications_path(api_user))

        follow_redirect!

        expect(response.body).to include("Permissions successfully updated")
      end

      it "does not update permissions and sets not found status code if the user only has a revoked access token" do
        application = create(:oauth_application)
        permission = create(:permission, oauth_application: application)

        api_user = create(:api_user,
                          with_signin_permissions_for: [application])

        create(:oauth_access_token, application:, resource_owner_id: api_user.id, revoked_at: Time.current)

        patch api_user_application_permissions_path(api_user, application, params: { application: { permission_ids: [permission.id] } })

        expect(api_user.permission_ids_for(application)).to contain_exactly(application.signin_permission.id)
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
