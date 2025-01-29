require "rails_helper"

RSpec.describe "/users/password", type: :request do
  let!(:user) { create(:user) }
  let!(:reset_password_token) { user.send_reset_password_instructions }

  describe "GET /edit" do
    it "shows password reset form" do
      get edit_user_password_path, params: { reset_password_token: }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Change your password")

      assert_select "form[action='#{user_password_path}']" do
        assert_select "input[type='hidden'][name='user[reset_password_token]']"
        assert_select "input[type='password'][name='user[password]']"
        assert_select "input[type='password'][name='user[password_confirmation]']"
      end
    end

    it "shows an error page if password reset token is invalid" do
      get edit_user_password_path, params: { reset_password_token: "not_a_real_token" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("This link to set a new password doesn't work")
    end

    it "shows an error page if password reset token has expired" do
      user.update!(reset_password_sent_at: 1.year.ago)

      get edit_user_password_path, params: { reset_password_token: }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("This link to set a new password doesn't work")
    end
  end
end
