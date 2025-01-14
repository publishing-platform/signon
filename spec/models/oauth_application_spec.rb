require "rails_helper"

RSpec.describe OauthApplication, type: :model do
  it "has a signin permission on create" do
    expect(create(:oauth_application).signin_permission).not_to be nil
  end

  describe "#sorted_permissions" do
    it "sorts the applications permissions but returns signin permission first" do
      app = create(:oauth_application, with_permissions: %w[x a r c])
      expect(app.sorted_permissions.map(&:name)).to eq %w[signin a c r x]
    end

    it "excludes signin permission if requested" do
      app = create(:oauth_application, with_permissions: %w[x a r c])
      expect(app.sorted_permissions(include_signin: false).map(&:name)).to eq %w[a c r x]
    end
  end

  describe ".api_only (scope)" do
    let(:app) { create(:oauth_application) }

    it "includes apps that are api only" do
      app.update!(api_only: true)
      expect(described_class.api_only).to eq [app]
    end

    it "excludes apps that are not api only" do
      expect(described_class.api_only).to eq []
    end
  end

  describe ".not_api_only" do
    let(:app) { create(:oauth_application) }

    it "includes apps that are not api only" do
      expect(described_class.not_api_only).to eq [app]
    end

    it "excludes apps that are api only" do
      app.update!(api_only: true)
      expect(described_class.not_api_only).to eq []
    end
  end

  describe ".can_signin" do
    it "returns applications that the user can signin into" do
      user = create(:user)
      app = create(:oauth_application)
      user.grant_application_signin_permission(app)

      expect(described_class.can_signin(user)).to eq [app]
    end

    it "does not return applications that the user can't signin into" do
      user = create(:user)
      create(:oauth_application)

      expect(described_class.can_signin(user)).to eq []
    end
  end

  describe ".without_signin_permission_for" do
    let(:user) { create(:user) }
    let(:app) { create(:oauth_application) }

    it "excludes applications the user has the signin permission for" do
      user.grant_application_signin_permission(app)

      expect(described_class.without_signin_permission_for(user)).to eq []
    end

    it "includes applications the user does not have the signin permission for" do
      create(:permission, oauth_application: app, name: "not-signin")

      user.grant_application_permission(app, "not-signin")
      expect(described_class.without_signin_permission_for(user)).to eq [app]
    end

    it "includes applications the user doesn't have any permissions for" do
      expect(described_class.without_signin_permission_for(user)).to eq [app]
    end
  end

  describe ".ordered_by_name" do
    it "returns applications ordered by name" do
      application_named_foo = create(:oauth_application, name: "Foo")
      application_named_bar = create(:oauth_application, name: "Bar")
      application_named_qux = create(:oauth_application, name: "Qux")

      expect(described_class.ordered_by_name).to eq [application_named_bar, application_named_foo, application_named_qux]
    end
  end
end
