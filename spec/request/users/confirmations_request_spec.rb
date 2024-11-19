require "rails_helper"

RSpec.describe "User confirmations", type: :request do
  # let(:user) { create(:user) }
  # let!(:organisation) { create(:organisation) }

  describe "GET new" do
    it "is disabled" do
      get new_user_confirmation_path

      expect(response).to redirect_to(new_user_session_path)
      follow_redirect!

      expect(response.body).to include("Please contact support to request a new confirmation email.")
    end
  end

  describe "POST create" do
    it "is disabled" do
      post user_confirmation_path

      expect(response).to redirect_to(new_user_session_path)
      follow_redirect!

      expect(response.body).to include("Please contact support to request a new confirmation email.")
    end
  end
end
