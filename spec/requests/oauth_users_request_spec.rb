require "rails_helper"

RSpec.describe "/user", type: :request do
  let(:application) { create(:oauth_application) }
  let(:user) { create(:user) }

  describe "GET /show" do
    it "successfully fetches json profile with a valid oauth token" do
      user.grant_application_signin_permission(application)

      access_token = create(:oauth_access_token, application:, resource_owner_id: user.id)
      get "/user.json", params: { client_id: application.uid }, headers: { Authorization: "Bearer #{access_token.token}" }

      expect(response).to have_http_status(:ok)
      presenter = UserOauthPresenter.new(user, application)
      expect(response.body).to eql(presenter.as_hash.to_json)
    end

    it "includes permissions" do
      user.grant_application_signin_permission(application)

      access_token = create(:oauth_access_token, application:, resource_owner_id: user.id)
      get "/user.json", params: { client_id: application.uid }, headers: { Authorization: "Bearer #{access_token.token}" }

      json = JSON.parse(response.body)
      expect(json["user"]["permissions"]).to contain_exactly(Permission::SIGNIN_NAME)
    end

    it "only includes permissions for the relevant app" do
      other_application = create(:oauth_application)
      user.grant_application_signin_permission(application)
      user.grant_application_signin_permission(other_application)

      access_token = create(:oauth_access_token, application:, resource_owner_id: user.id)
      get "/user.json", params: { client_id: application.uid }, headers: { Authorization: "Bearer #{access_token.token}" }

      json = JSON.parse(response.body)
      expect(json["user"]["permissions"]).to contain_exactly(Permission::SIGNIN_NAME)
    end

    it "does not succeed if client_id is not provided" do
      user.grant_application_signin_permission(application)

      access_token = create(:oauth_access_token, application:, resource_owner_id: user.id)
      get "/user.json", params: {}, headers: { Authorization: "Bearer #{access_token.token}" }

      expect(response).to have_http_status(:unauthorized)
    end

    it "does not succeed if oauth token is invalid" do
      user.grant_application_signin_permission(application)

      access_token = create(:oauth_access_token, application:, resource_owner_id: user.id)
      get "/user.json", params: { client_id: application.uid }, headers: { Authorization: "Bearer #{access_token.token.sub(/[0-9]/, 'x')}" }

      expect(response).to have_http_status(:unauthorized)
    end

    it "does not succeed without a bearer header" do
      user.grant_application_signin_permission(application)

      get "/user.json", params: { client_id: application.uid }

      expect(response).to have_http_status(:unauthorized)
    end

    it "does not succeed with a token for another app" do
      other_application = create(:oauth_application)
      user.grant_application_signin_permission(application)

      access_token = create(:oauth_access_token, application: other_application, resource_owner_id: user.id)
      get "/user.json", params: { client_id: application.uid }, headers: { Authorization: "Bearer #{access_token.token}" }

      expect(response).to have_http_status(:unauthorized)
    end

    it "does not succeed with an expired token" do
      user.grant_application_signin_permission(application)

      access_token = create(:oauth_access_token, application:, resource_owner_id: user.id)
      access_token.update_columns(created_at: 3.days.ago, expires_in: 30)

      get "/user.json", params: { client_id: application.uid }, headers: { Authorization: "Bearer #{access_token.token}" }

      expect(response).to have_http_status(:unauthorized)
    end

    it "does not succeed if user does not have 'signin' permission for the relevant app" do
      access_token = create(:oauth_access_token, application:, resource_owner_id: user.id)
      get "/user.json", params: { client_id: application.uid }, headers: { Authorization: "Bearer #{access_token.token}" }

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
