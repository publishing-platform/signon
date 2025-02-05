require "rails_helper"

RSpec.describe "/users/confirmation", type: :request do
  let(:user) { create(:user) }
  let(:confirmation_token) { "a55hgy68" }
  let!(:user_with_pending_email_change) do
    create(:user_with_pending_email_change, confirmation_token:)
  end

  describe "GET /new" do
    it "is disabled" do
      get new_user_confirmation_path

      expect(response).to redirect_to(new_user_session_path)
      follow_redirect!

      expect(response.body).to include("Please contact support to request a new confirmation email.")
    end
  end

  describe "POST /create" do
    it "is disabled" do
      post user_confirmation_path

      expect(response).to redirect_to(new_user_session_path)
      follow_redirect!

      expect(response.body).to include("Please contact support to request a new confirmation email.")
    end
  end

  describe "GET /show" do
    context "when user is not authenticated" do
      it "rejects an invalid token" do
        get user_confirmation_path, params: { confirmation_token: "fake" }

        expect(response).to redirect_to(new_user_session_path)
        follow_redirect!

        expect(response.body).to include("Please contact support to request a new confirmation email.")
      end

      it "renders a form for confirming email change" do
        get user_confirmation_path, params: { confirmation_token: }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Confirm change of email address")
        assert_select "input[name='user[password]']"
        assert_select "input[type=hidden][name=confirmation_token][value=?]", confirmation_token
      end
    end

    context "when user is authenticated" do
      before do
        sign_in user_with_pending_email_change
      end

      after do
        sign_out user_with_pending_email_change
      end

      it "rejects an invalid token" do
        get user_confirmation_path, params: { confirmation_token: "fake" }

        expect(response).to redirect_to(root_path)
        follow_redirect!

        expect(response.body).to include("Please contact support to request a new confirmation email.")
      end

      it "accepts the confirmation and redirects to root" do
        get user_confirmation_path, params: { confirmation_token: }

        expect(response).to redirect_to(root_path)
        follow_redirect!

        expect(response.body).to include("Your email address has been successfully confirmed.")
        expect(user_with_pending_email_change.reload.email).to eql "new@email.com"
      end
    end

    context "when authenticated as someone else" do
      before do
        sign_in user
      end

      after do
        sign_out user
      end

      it "rejects the attempt" do
        get user_confirmation_path, params: { confirmation_token: }

        expect(response).to redirect_to(root_path)
        follow_redirect!

        expect(response.body).to include("It appears you followed a link meant for another user.")
        expect(user_with_pending_email_change.reload.email).to eql "old@email.com"
      end
    end
  end

  describe "PUT /update" do
    it "accepts the confirmation with correct token and password, and redirects to root" do
      put users_confirmation_path, params: {
        confirmation_token:,
        user: {
          password: "this 1s 4 v3333ry s3cur3 p4ssw0rd.!Z",
        },
      }

      expect(response).to redirect_to(root_path)
      follow_redirect! # redirect to root
      follow_redirect! # redirects to 2fa set up prompt

      expect(response.body).to include("Your email address has been successfully confirmed.")
      expect(user_with_pending_email_change.reload.email).to eql "new@email.com"
    end

    it "rejects with an incorrect token" do
      put users_confirmation_path, params: {
        confirmation_token: "fake",
        user: {
          password: "this 1s 4 v3333ry s3cur3 p4ssw0rd.!Z",
        },
      }

      expect(response.body).to include("Password was incorrect") # not sure this is desirable behaviour?
      expect(user_with_pending_email_change.reload.email).to eql "old@email.com"
    end

    it "rejects with an incorrect password" do
      put users_confirmation_path, params: {
        confirmation_token:,
        user: {
          password: "incorrect password",
        },
      }

      expect(response.body).to include("Password was incorrect")
      expect(user_with_pending_email_change.reload.email).to eql "old@email.com"
    end
  end
end
