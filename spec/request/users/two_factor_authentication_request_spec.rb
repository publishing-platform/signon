require "rails_helper"

RSpec.describe "User two factor authentication", type: :request do
  let(:user) { create(:user) }

  describe "GET prompt" do
    context "when user is not authenticated" do
      it "redirects user to sign in" do
        get prompt_two_factor_authentication_path

        assert_not_authenticated
      end
    end
  end

  describe "GET show" do
    context "when user is not authenticated" do
      it "redirects user to sign in" do
        get two_factor_authentication_path

        assert_not_authenticated
      end
    end
  end

  describe "PUT update" do
    context "when user is not authenticated" do
      it "redirects user to sign in" do
        put two_factor_authentication_path

        assert_not_authenticated
      end
    end
  end
end
