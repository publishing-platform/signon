require "rails_helper"

RSpec.describe "User invitations", type: :request do
  let(:user) { create(:user) }

  describe "GET new" do
    context "when user is not authenticated" do
      it "redirects user to sign in" do
        get new_user_invitation_path

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
        get new_user_invitation_path

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

      it "displays new user form" do
        get new_user_invitation_path

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Create new user")
      end
    end
  end

  describe "POST create" do
    context "when user is not authenticated" do
      it "redirects user to sign in" do
        post user_invitation_path

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
        post user_invitation_path, params: { user: { name: "Test", email: "test@test.co.uk" } }

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

      context "and valid parameters are provided" do
        it "sends invitation to new user" do
          post user_invitation_path, params: { user: { name: "Test", email: "test@test.co.uk" } }
          follow_redirect!

          expect(response.body).to include("An invitation email has been sent to test@test.co.uk")
        end

        it "creates user" do
          expect {
            post user_invitation_path, params: { user: { name: "Test", email: "test@test.co.uk" } }
          }.to change(User, :count).by(1)
        end
      end

      context "and email is blank" do
        it "displays validation error" do
          post user_invitation_path, params: { user: { name: "Test" } }
          expect(response.body).to include("Email can't be blank")
        end

        it "does not create user" do
          expect {
            post user_invitation_path, params: { user: { name: "Test" } }
          }.to change(User, :count).by(0)
        end
      end

      context "and name is blank" do
        it "displays validation error" do
          post user_invitation_path, params: { user: { email: "test@test.co.uk" } }
          expect(response.body).to include("Name can't be blank")
        end

        it "does not create user" do
          expect {
            post user_invitation_path, params: { user: { email: "test@test.co.uk" } }
          }.to change(User, :count).by(0)
        end
      end
    end
  end

  describe "PUT resend" do
    let(:invited) { create(:invited_user) }

    context "when user is not authenticated" do
      it "redirects user to sign in" do
        put resend_user_invitation_path(invited)

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
        put resend_user_invitation_path(invited)

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

      it "resends signup email" do
        put resend_user_invitation_path(invited)
        follow_redirect!

        expect(response.body).to include("Resent account signup email to #{invited.email}")
      end
    end
  end
end
