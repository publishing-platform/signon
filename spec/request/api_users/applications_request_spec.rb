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

      it "displays list of applications user has access to" do
        get api_user_applications_path(api_user)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Apps #{api_user.name} has access to")
      end

      it "sets not found status code if user does not exist" do
        get api_user_applications_path({ api_user_id: "non-existent-api-user-id" })

        expect(response).to have_http_status(:not_found)
      end
    end    
  end
end