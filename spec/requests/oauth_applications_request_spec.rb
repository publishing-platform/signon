require "rails_helper"

RSpec.describe "/oauth_applications", type: :request do
  let(:user) { create(:user) }
  let(:application) { create(:oauth_application, name: "My first app") }

  describe "GET /index" do
    context "when user is not authenticated" do
      it "redirects user to sign in" do
        get oauth_applications_path

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
        get oauth_applications_path

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

      it "lists applications in separate tabs for Active and Retired" do
        create(:oauth_application, name: "My first app")
        create(:oauth_application, name: "My retired app", retired: true)

        get oauth_applications_path

        assert_select "#active-tab-pane td", text: /My first app/
        assert_select "#retired-tab-pane td", text: /My first app/, count: 0

        assert_select "#active-tab-pane td", text: /My retired app/, count: 0
        assert_select "#retired-tab-pane td", text: /My retired app/
      end

      it "lists applications in alphabetical order" do
        create(:oauth_application, name: "My app B")
        create(:oauth_application, name: "My app A")
        create(:oauth_application, name: "My app C")

        get oauth_applications_path

        assert_select "#active-tab-pane tr:first-child td:first-child", text: /My app A/
        assert_select "#active-tab-pane tr:last-child td:first-child", text: /My app C/
      end

      it "renders link to create new application" do
        get oauth_applications_path

        expect(response).to have_http_status(:ok)
        assert_select "a[href='#{new_oauth_application_path}']", text: "Create application"
      end
    end
  end

  describe "GET /edit" do
    context "when user is not authenticated" do
      it "redirects user to sign in" do
        get edit_oauth_application_path(application)

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
        get edit_oauth_application_path(application)

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

      it "renders a form for editing existing application" do
        get edit_oauth_application_path(application)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Edit #{application.name}")

        assert_select "input[name='oauth_application[name]'][value='#{application.name}']"
      end

      it "renders a link to edit application permissions" do
        get edit_oauth_application_path(application)

        assert_select "a[href='#{oauth_application_permissions_path(application)}']", text: "Edit application permissions"
      end

      it "sets not found status code if the application does not exist" do
        get edit_oauth_application_path({ id: "non-existent-application-id" })

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "PATCH /update" do
    context "when user is not authenticated" do
      it "redirects user to sign in" do
        patch oauth_application_path(application)

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
        patch oauth_application_path(application)

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

      it "redirects and displays success message" do
        patch oauth_application_path(application), params: { oauth_application: { name: "Another name" } }

        expect(response).to redirect_to(oauth_applications_path)
        follow_redirect!

        expect(response.body).to include("Successfully updated Another name")
      end

      it "updates application" do
        patch oauth_application_path(application), params: { oauth_application: { name: "Another name" } }

        expect(application.reload.name).to eql("Another name")
      end

      it "allows application to be set as retired" do
        patch oauth_application_path(application), params: { oauth_application: { retired: "1" } }

        expect(application.reload.retired?).to be(true)
      end

      it "allows application to be set as api only" do
        patch oauth_application_path(application), params: { oauth_application: { api_only: "1" } }

        expect(application.reload.api_only?).to be(true)
      end

      it "displays error and does not update application if name is not provided" do
        patch oauth_application_path(application), params: { oauth_application: { name: "" } }

        expect(response.body).to include("Name can't be blank")

        expect(application.reload.name).to eql("My first app")
      end

      it "displays error and does not update application if redirect uri is not provided" do
        redirect_uri = application.redirect_uri

        patch oauth_application_path(application), params: { oauth_application: { redirect_uri: "" } }

        expect(response.body).to include("Redirect uri can't be blank")

        expect(application.reload.redirect_uri).to eql(redirect_uri)
      end

      it "displays error and does not update application if uid is not provided" do
        uid = application.uid

        patch oauth_application_path(application), params: { oauth_application: { uid: "" } }

        expect(response.body).to include("Uid can't be blank")

        expect(application.reload.uid).to eql(uid)
      end

      it "displays error and does not update application if secret is not provided" do
        secret = application.secret

        patch oauth_application_path(application), params: { oauth_application: { secret: "" } }

        expect(response.body).to include("Secret can't be blank")

        expect(application.reload.secret).to eql(secret)
      end

      it "sets not found status code if the application does not exist" do
        patch oauth_application_path({ id: "non-existent-application-id" })

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "GET /new" do
    context "when user is not authenticated" do
      it "redirects user to sign in" do
        get new_oauth_application_path

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
        get new_oauth_application_path

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

      it "renders a form for creating a new application" do
        get new_oauth_application_path

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Create new application")

        assert_select "input[name='oauth_application[name]']"
      end
    end
  end

  describe "POST /create" do
    context "when user is not authenticated" do
      it "redirects user to sign in" do
        post oauth_applications_path

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
        post oauth_applications_path

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

      it "redirects and displays success message" do
        post oauth_applications_path, params: {
          oauth_application: {
            name: "My app",
            redirect_uri: "https://app.test.publishing-platform.co.uk/callback",
          },
        }

        expect(response).to redirect_to(oauth_applications_path)
        follow_redirect!

        expect(response.body).to include("Successfully created My app")
      end

      it "creates application" do
        expect {
          post oauth_applications_path, params: {
            oauth_application: {
              name: "My app",
              redirect_uri: "https://app.test.publishing-platform.co.uk/callback",
            },
          }
        }.to change(OauthApplication, :count).by(1)
      end

      it "displays error and does not create permission if name is not provided" do
        post oauth_applications_path, params: {
          oauth_application: {
            name: "",
            redirect_uri: "https://app.test.publishing-platform.co.uk/callback",
          },
        }

        expect(response.body).to include("Name can't be blank")
        expect(OauthApplication.count).to be(0)
      end

      it "displays error and does not create permission if redirect_uri is not provided" do
        post oauth_applications_path, params: {
          oauth_application: {
            name: "My app",
            redirect_uri: "",
          },
        }

        expect(response.body).to include("Redirect uri can't be blank")
        expect(OauthApplication.count).to be(0)
      end
    end
  end
end
