require "rails_helper"

RSpec.describe Permission, type: :model do
  let(:user) { create(:user) }

  it "does not allow name of signin permission to be changed" do
    application = create(:oauth_application)

    expect {
      application.signin_permission.update!(name: "sign-in")
    }.to raise_error(ActiveRecord::RecordInvalid)
  end

  it "allows name of permissions other than signin to be changed" do
    permission = create(:permission, name: "writer")

    expect {
      permission.update!(name: "reader")
    }.not_to raise_error
  end

  it "does not allow duplicate permission names for an application" do
    oauth_application = create(:oauth_application)
    create(:permission, name: "writer", oauth_application:)
    copy_cat_permission = build(:permission, name: "writer", oauth_application:)

    expect(copy_cat_permission.valid?).to be false
    expect(copy_cat_permission.errors[:name]).to include("has already been taken")
  end

  it "does not allow a permission to be created without an associated application" do
    expect {
      create(:permission, oauth_application: nil)
    }.to raise_error(ActiveRecord::RecordInvalid)
  end
end
