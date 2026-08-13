require "rails_helper"

RSpec.describe "api/users", type: :request do
  let(:signon_api) { create(:oauth_application, name: "Signon API") }
  let(:application) { create(:oauth_application) }
  let(:user) { create(:user) }

  describe "GET /index" do
    context "when user is an admin user" do
      before do
        user.grant_application_signin_permission(signon_api)
        sign_in(user)
      end

      it "does not allow access to the API endpoint" do
        get "/api/users"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when user has a valid token" do
      let(:api_user) { create(:api_user, with_signin_permissions_for: [signon_api]) }
      let(:access_token) { create(:oauth_access_token, resource_owner_id: api_user.id, application: signon_api) }

      it "returns users with given UUIDs" do
        user1 = create(:user, uid: SecureRandom.uuid)
        _user2 = create(:user, uid: SecureRandom.uuid)
        user3 = create(:user, uid: SecureRandom.uuid)

        get "/api/users", params: { uuids: [user1.uid, user3.uid] }, headers: { Authorization: "Bearer #{access_token.token}" }

        expect(response).to have_http_status(:ok)

        body = JSON.parse(response.body).map(&:deep_symbolize_keys)

        expect(body.length).to be 2
        expect(body[0]).to eql Api::UserPresenter.present(user1)
        expect(body[1]).to eql Api::UserPresenter.present(user3)
      end

      it "returns an empty array when no users found" do
        get "/api/users", params: { uuids: [SecureRandom.uuid] }, headers: { Authorization: "Bearer #{access_token.token}" }

        expect(response).to have_http_status(:ok)

        body = JSON.parse(response.body).map(&:deep_symbolize_keys)

        expect(body.length).to be 0
      end
    end

    context "when user has an invalid token" do
      it "does not allow access to the API endpoint" do
        get "/api/users", headers: { Authorization: "Bearer FAKE_BEARER_TOKEN" }

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when user has a valid token for another application" do
      let(:api_user) { create(:api_user, with_signin_permissions_for: [application]) }
      let(:access_token) { create(:oauth_access_token, resource_owner_id: api_user.id, application:) }

      it "does not allow access to the API endpoint" do
        get "/api/users", headers: { Authorization: "Bearer #{access_token.token}" }

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
