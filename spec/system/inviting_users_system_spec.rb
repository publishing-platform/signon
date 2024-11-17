require "rails_helper"

RSpec.describe "Inviting users", type: :system do
  let(:user) { create(:admin_user) }
  let!(:organisation) { create(:organisation) }
  
  before do
    visit new_user_session_path
  end
  
  context "when user is an admin" do
    before do
      signin_with(user)
      visit new_user_invitation_path
    end 
    
    it "allows access" do
      expect(page).to have_text("Create new user")
    end    
  end
end