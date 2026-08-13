require "rails_helper"

RSpec.describe Api::UserPresenter do
  describe "#present" do
    let(:organisation) { build(:organisation) }
    let(:user) { build(:user, organisation:) }

    it "returns a presented version of the user" do
      presented_user = described_class.present(user)

      expect(presented_user).to eql({
        uid: user.uid,
        name: user.name,
        email: user.email,
        organisation: {
          content_id: organisation.content_id,
          name: organisation.name,
          slug: organisation.slug,
        },
      })
    end

    it "allows a nil organisation" do
      user.organisation = nil

      presented_user = described_class.present(user)

      expect(presented_user).to eql({
        uid: user.uid,
        name: user.name,
        email: user.email,
        organisation: nil,
      })
    end
  end

  describe "#present_many" do
    it "presents an array of users" do
      users = build_list(:user, 4)
      result = described_class.present_many(users)

      expect(result).to eql(users.map { |u| described_class.present(u) })
    end
  end
end
