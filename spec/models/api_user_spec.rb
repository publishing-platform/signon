require "rails_helper"

RSpec.describe ApiUser, type: :model do
  it "is not valid if require 2fa is set to true" do
    user = build(:api_user, require_2fa: true)
    expect(user.valid?).to be false
  end

  it "is valid if require 2fa is set to false" do
    user = build(:api_user, require_2fa: false)
    expect(user.valid?).to be true
  end
end
