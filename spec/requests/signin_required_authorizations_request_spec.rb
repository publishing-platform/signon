require "rails_helper"

RSpec.describe "/oauth/authorize", type: :request do
  let(:application) { create(:oauth_application) }
  let(:user) { create(:user) }

  describe "GET /new" do
    context "when user is not authenticated" do
      it "redirects user to sign in" do
        application = create(:oauth_application)

        get oauth_authorization_path, params: { response_type: "code", client_id: application.uid, redirect_uri: application.redirect_uri }

        assert_not_authenticated
      end
    end

    context "when user is authenticated" do
      before do
        user.grant_application_signin_permission(application)
        sign_in(user)
      end

      context "and parameters are valid" do
        before do
          get oauth_authorization_path, params: { response_type: "code", client_id: application.uid, redirect_uri: application.redirect_uri }
        end

        it "redirects to the application redirect uri and includes the access grant code" do
          expect(response).to have_http_status(:redirect)
          expect(response.location).to eql("#{application.redirect_uri}\?code=#{Doorkeeper::AccessGrant.first.token}")
        end

        it "issues a grant" do
          expect(Doorkeeper::AccessGrant.count).to be(1)
        end

        it "does not issue a token" do
          expect(OauthAccessToken.count).to be(0)
        end
      end

      context "and native url is provided" do
        before do
          application.update! redirect_uri: "urn:ietf:wg:oauth:2.0:oob"
          get oauth_authorization_path, params: { response_type: "code", client_id: application.uid, redirect_uri: application.redirect_uri }
        end

        it "redirects to the native url endpoint and include the access grant code" do
          expect(response).to have_http_status(:redirect)
          expect(response.location).to match(/oauth\/authorize\/native\?code=#{Doorkeeper::AccessGrant.first.token}/)
        end

        it "issues a grant" do
          expect(Doorkeeper::AccessGrant.count).to be(1)
        end

        it "does not issue a token" do
          expect(OauthAccessToken.count).to be(0)
        end
      end

      context "and parameters are invalid" do
        before do
          get oauth_authorization_path, params: { response_type: "code", client_id: "invalid", redirect_uri: "invalid" }
        end

        it "does not redirect" do
          expect(response).to have_http_status(:ok)
        end

        it "does not issue a grant" do
          expect(Doorkeeper::AccessGrant.count).to be(0)
        end

        it "does not issue a token" do
          expect(OauthAccessToken.count).to be(0)
        end
      end
    end

    context "when user does not have 'signin' permission for the application" do
      before do
        sign_in(user)
        get oauth_authorization_path, params: { response_type: "code", client_id: application.uid, redirect_uri: application.redirect_uri }
      end

      it "redirects after authorization" do
        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(signin_required_path)
      end

      it "does not issue a grant" do
        expect(Doorkeeper::AccessGrant.count).to be(0)
      end

      it "does not issue a token" do
        expect(OauthAccessToken.count).to be(0)
      end
    end
  end

  describe "POST /create" do
    before do
      sign_in(user)
    end

    it "sets not found status code" do
      post oauth_authorization_path
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "DELETE /destroy" do
    before do
      sign_in(user)
    end

    it "sets not found status code" do
      delete oauth_authorization_path
      expect(response).to have_http_status(:not_found)
    end
  end
end
