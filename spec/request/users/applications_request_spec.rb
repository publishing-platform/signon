require "rails_helper"

RSpec.describe "User applications", type: :request do
  let(:user) { create(:user) }
  let(:application) { create(:oauth_application) }

  describe "GET index" do
    context "when user is not authenticated" do
      it "redirects user to sign in" do
        get user_applications_path(user)

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
        get user_applications_path(user)

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

      it "lists apps user has access to" do
        get user_applications_path(user)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Apps #{user.name} has access to")
      end 
    end   
  end

  describe "GET show" do
    context "when user is not authenticated" do
      it "redirects user to sign in" do
        get user_application_path(user, application)

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
        get user_application_path(user, application)

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

      it "redirects to user applications list" do
        get user_application_path(user, application)

        expect(response).to redirect_to(user_applications_path(user))   
      end 
    end   
  end
end
