require "rails_helper"

RSpec.describe "API User authorisations", type: :request do
  let(:user) { create(:user) }
  let(:api_user) { create(:api_user) }
  let(:application) { create(:oauth_application) }
  let(:access_token) { create(:oauth_access_token, resource_owner_id: api_user.id) }

  describe "GET new" do
    context "when user is not authenticated" do
      it "redirects user to sign in" do
        get new_api_user_authorisation_path(api_user)

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
        get new_api_user_authorisation_path(api_user)

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

      it "displays new authorisation form" do
        get new_api_user_authorisation_path(api_user)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Create new access token for #{api_user.name}")
      end

      it "sets not found status code if user does not exist" do
        get new_api_user_authorisation_path({ api_user_id: "non-existent-api-user-id" })

        expect(response).to have_http_status(:not_found)
      end

      it "sets not found status code if not api user" do
        get new_api_user_authorisation_path(user)

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "POST create" do
    context "when user is not authenticated" do
      it "redirects user to sign in" do
        post api_user_authorisations_path(api_user)

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
        post api_user_authorisations_path(api_user, params: { authorisation: { application_id: application.id } })

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

      context "and valid parameters are provided" do
        it "redirects and displays success message" do
          post api_user_authorisations_path(api_user, params: { authorisation: { application_id: application.id } })

          expect(response).to redirect_to(manage_tokens_api_user_path(api_user))
          follow_redirect!

          expect(response.body).to include("Token created")
        end

        it "creates access token" do
          expect {
            post api_user_authorisations_path(api_user, params: { authorisation: { application_id: application.id } })
          }.to change(OauthAccessToken, :count).by(1)
        end

        it "grants user signin permission" do
          post api_user_authorisations_path(api_user, params: { authorisation: { application_id: application.id } })

          expect(api_user.has_access_to?(application)).to be true
        end
      end

      context "and application is blank" do
        it "raises not null violation error" do
          expect {
            post api_user_authorisations_path(api_user, params: { authorisation: { application_id: nil } })
          }.to raise_error(ActiveRecord::NotNullViolation)
        end
      end

      context "and application does not exist" do
        it "raises invalid foreign key error" do
          expect {
            post api_user_authorisations_path(api_user, params: { authorisation: { application_id: "non-existent-application-id" } })
          }.to raise_error(ActiveRecord::InvalidForeignKey)
        end
      end
    end
  end

  describe "GET edit" do
    context "when user is not authenticated" do
      it "redirects user to sign in" do
        get edit_api_user_authorisation_path(api_user, access_token)

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
        get edit_api_user_authorisation_path(api_user, access_token)

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

      it "displays a form for revoking API access to application" do
        get edit_api_user_authorisation_path(api_user, access_token)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Revoke token giving #{api_user.name} access to #{access_token.application.name}")
      end

      it "sets not found status code if user does not exist" do
        get edit_api_user_authorisation_path({ api_user_id: "non-existent-api-user-id" }, access_token)

        expect(response).to have_http_status(:not_found)
      end

      it "sets not found status code if not api user" do
        get edit_api_user_authorisation_path(user, access_token)

        expect(response).to have_http_status(:not_found)
      end

      it "sets not found status code if access token does not exist" do
        get edit_api_user_authorisation_path(api_user, { id: "non-existent-access-token-id" })

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "POST revoke" do
    context "when user is not authenticated" do
      it "redirects user to sign in" do
        post revoke_api_user_authorisation_path(api_user, access_token)

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
        post revoke_api_user_authorisation_path(api_user, access_token)

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

      it "revokes access token" do
        post revoke_api_user_authorisation_path(api_user, access_token)

        expect(access_token.reload.revoked?).to be true
      end

      it "redirects to manage tokens page" do
        post revoke_api_user_authorisation_path(api_user, access_token)

        expect(response).to redirect_to(manage_tokens_api_user_path(api_user))
      end

      it "displays success notice" do
        post revoke_api_user_authorisation_path(api_user, access_token)
        follow_redirect!

        expect(response.body).to include("Access for #{access_token.application.name} was revoked")
      end

      context "when revocation fails" do
        before do
          allow(ApiUser).to receive(:find).and_return(api_user)
          allow(api_user.authorisations).to receive(:find).and_return(access_token)
          allow(access_token).to receive(:revoke).and_return(false)
        end

        it "redirects to manage tokens page" do
          post revoke_api_user_authorisation_path(api_user, access_token)

          expect(response).to redirect_to(manage_tokens_api_user_path(api_user))
        end

        it "displays error notice" do
          post revoke_api_user_authorisation_path(api_user, access_token)
          follow_redirect!

          expect(response.body).to include("There was an error while revoking access for #{access_token.application.name}")
        end
      end

      it "sets not found status code if user does not exist" do
        post revoke_api_user_authorisation_path({ api_user_id: "non-existent-api-user-id" }, access_token)

        expect(response).to have_http_status(:not_found)
      end

      it "sets not found status code if not api user" do
        post revoke_api_user_authorisation_path(user, access_token)

        expect(response).to have_http_status(:not_found)
      end

      it "sets not found status code if access token does not exist" do
        post revoke_api_user_authorisation_path(api_user, { id: "non-existent-access-token-id" })

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
