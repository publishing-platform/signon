require "rails_helper"

RSpec.describe "Permissions", type: :request do
  let(:user) { create(:user) }
  let(:application) { create(:oauth_application) }

  describe "GET edit" do
    context "when user is not authenticated" do
      it "redirects user to sign in" do
        get edit_user_application_permissions_path(user, application)

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
        get edit_user_application_permissions_path(user, application)

        assert_not_authorised
      end
    end
  end
end
