require "rails_helper"

RSpec.describe RootHelper do
  describe "#signin_required_title" do
    it "returns generic message if application is not provided" do
      expect(helper.signin_required_title(nil)).to eql "You don’t have permission to use this app."
    end

    it "returns customised message if application is provided" do
      application = create(:oauth_application)
      expect(helper.signin_required_title(application)).to eql "You don’t have permission to sign in to #{application.name}."
    end
  end
end
