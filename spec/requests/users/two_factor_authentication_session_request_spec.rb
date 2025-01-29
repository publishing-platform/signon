require "rails_helper"

RSpec.describe "/users/two_factor_authentication/session", type: :request do
  let(:user) { create(:user) }

  describe "GET /new" do
    context "when user is not authenticated" do
      it "redirects user to sign in" do
        get new_two_factor_authentication_session_path

        assert_not_authenticated
      end
    end
  end

  describe "POST /create" do
    context "when user is not authenticated" do
      it "redirects user to sign in" do
        post two_factor_authentication_session_path

        assert_not_authenticated
      end
    end
  end
end
