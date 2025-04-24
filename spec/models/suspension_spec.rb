require "rails_helper"

RSpec.describe Suspension, type: :model do
  let(:user) { create(:user) }

  it "is valid when a reason is given for a suspension" do
    suspension = described_class.new(suspend: true, reason_for_suspension: "A reason")
    expect(suspension.valid?).to be true
  end

  it "is valid when no reason is given for an unsuspension" do
    suspension = described_class.new(suspend: false)
    expect(suspension.valid?).to be true
  end

  it "is ivalid when no reason is given for a suspension" do
    suspension = described_class.new(suspend: true)
    expect(suspension.valid?).to be false
  end

  it "does not save an invalid suspension" do
    suspension = described_class.new(suspend: true)

    expect(suspension.valid?).to be false
    expect(suspension.save).to be false
  end

  it "suspends a user when suspend is true and a reason is given" do
    suspension = described_class.new(suspend: true, reason_for_suspension: "A reason", user:)
    suspension.save!

    user.reload

    expect(user.suspended?).to be true
    expect(user.reason_for_suspension).to eql "A reason"
  end

  it "unsuspends a user when suspend is false" do
    user = create(:suspended_user)

    suspension = described_class.new(suspend: false, user:)
    suspension.save!

    user.reload

    expect(user.suspended?).to be false
    expect(user.reason_for_suspension).to be_nil
  end

  it "is suspended when suspend is true" do
    expect(described_class.new(suspend: true).suspended?).to be true
    expect(described_class.new(suspend: false).suspended?).to be false
  end
end
