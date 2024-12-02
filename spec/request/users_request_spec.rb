require "rails_helper"

RSpec.describe "Users", type: :request do
  let(:user) { create(:user) }

  describe "GET index" do
    context "when user is not authenticated" do
      it "redirects user to sign in" do
        get users_path

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
        get users_path

        assert_not_authorised
      end
    end

    context "when user is an admin user" do
      before do
        user.update!(role: "admin", name: "admin@email.com")
        sign_in user
      end

      after do
        sign_out user
      end

      it "renders list of users" do
        create(:user, email: "another_user@email.com")
        get users_path
        assert_select "table tr td:nth-child(1)", /another_user@email.com/
      end

      it "does not list api users" do
        create(:api_user, email: "api_user@email.com")
        get users_path
        assert_select "tr td:nth-child(1)", count: 0, text: /api_user@email.com/
      end

      it "renders link to invite new user" do
        get users_path

        expect(response).to have_http_status(:ok)
        assert_select "a[href='#{new_user_invitation_path}']", text: "Create user"
      end
    end
  end
end
