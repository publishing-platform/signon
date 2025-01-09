require "rails_helper"

RSpec.describe UserUpdatePermissionBuilder, type: :model do
  let(:application) { create(:oauth_application) }
  let(:permission) { create(:permission, oauth_application: application, name: "perm-1") }
  let(:user) { create(:user) }

  before do
    user.grant_permission(permission)
  end

  describe "#build" do
    it "returns users existing permission if not updatable and not selected" do
      builder = described_class.new(
        user:,
        updatable_permission_ids: [],
        selected_permission_ids: [],
      )

      expect(builder.build).to contain_exactly(permission.id)
    end

    it "removes users existing permission if updatable and not selected" do
      builder = described_class.new(
        user:,
        updatable_permission_ids: [permission.id],
        selected_permission_ids: [],
      )

      expect(builder.build.empty?).to be true
    end

    it "adds new permission if updatable and selected" do
      builder = described_class.new(
        user:,
        updatable_permission_ids: [1],
        selected_permission_ids: [1],
      )

      expect(builder.build).to contain_exactly(1, permission.id)
    end

    it "does not add new permission if updatable and not selected" do
      builder = described_class.new(
        user:,
        updatable_permission_ids: [1],
        selected_permission_ids: [],
      )

      expect(builder.build).to contain_exactly(permission.id)
    end

    it "does not add new permission if not updatable" do
      builder = described_class.new(
        user:,
        updatable_permission_ids: [1],
        selected_permission_ids: [2],
      )

      expect(builder.build).to contain_exactly(permission.id)
    end
  end
end
