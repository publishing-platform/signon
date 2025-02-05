require "rails_helper"

RSpec.describe "/users/:user_id/suspensions", type: :request do
  let(:user) { create(:user) }

  describe "GET /edit" do
    context "when user is not authenticated" do
      it "redirects user to sign in" do
        get edit_user_suspensions_path(user)

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
        get edit_user_suspensions_path(user)

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

      it "renders a form for editing user's suspension status" do
        get edit_user_suspensions_path(user)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Suspend or unsuspend #{user.name}")
        assert_select "input[type='checkbox'][name='user[suspended]'][value='1']", true
        assert_select "input[type='text'][name='user[reason_for_suspension]']", true
      end

      it "sets not found status code if the user does not exist" do
        get edit_user_suspensions_path({ user_id: "non-existent-user-id" })

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "PATCH /update" do
    context "when user is not authenticated" do
      it "redirects user to sign in" do
        patch user_suspensions_path(user)

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
        patch user_suspensions_path(user)

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

      context "when target user is active" do
        let(:active_user) { create(:active_user) }

        it "redirects and displays success message" do
          patch user_suspensions_path(active_user), params: { user: { suspended: "1", reason_for_suspension: "A reason" } }

          expect(response).to redirect_to(edit_user_path(active_user))
          follow_redirect!

          expect(response.body).to include("#{active_user.email} is now suspended")
        end

        it "suspends user" do
          patch user_suspensions_path(active_user), params: { user: { suspended: "1", reason_for_suspension: "A reason" } }

          expect(active_user.reload.suspended?).to be(true)
        end

        it "displays error and does not suspend user if reason is not provided" do
          patch user_suspensions_path(active_user), params: { user: { suspended: "1", reason_for_suspension: "" } }

          expect(response.body).to include("Reason for suspension can't be blank")

          expect(active_user.reload.suspended?).to be(false)
        end
      end

      context "when target user is suspended" do
        let(:suspended_user) { create(:suspended_user) }

        it "redirects and displays success message" do
          patch user_suspensions_path(suspended_user), params: { user: { reason_for_suspension: "" } }

          expect(response).to redirect_to(edit_user_path(suspended_user))
          follow_redirect!

          expect(response.body).to include("#{suspended_user.email} is now active")
        end

        it "activates user" do
          patch user_suspensions_path(suspended_user), params: { user: { reason_for_suspension: "" } }

          expect(suspended_user.reload.suspended?).to be(false)
        end

        it "allows updating of reason for suspension" do
          patch user_suspensions_path(suspended_user), params: { user: { suspended: "1", reason_for_suspension: "Another reason" } }

          expect(suspended_user.reload.suspended?).to be(true)
          expect(suspended_user.reload.reason_for_suspension).to eql("Another reason")
        end
      end

      it "sets not found status code if the application does not exist" do
        patch user_suspensions_path({ user_id: "non-existent-user-id" })

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
