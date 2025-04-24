require "rails_helper"

RSpec.describe User, type: :model do
  let(:user) { create(:user) }
  let(:admin_user) { create(:admin_user) }
  let(:invited_user) { create(:invited_user) }
  let(:active_user) { create(:active_user) }
  let(:suspended_user) { create(:suspended_user) }
  let(:locked_user) { create(:locked_user) }

  describe "#require_2fa" do
    it "defaults to true" do
      expect(user.require_2fa).to be true
    end
  end

  describe "#prompt_for_2fa" do
    context "when user has set up 2FA" do
      before do
        user.update!(otp_secret: "a secret")
      end

      it "is always false" do
        expect(user.prompt_for_2fa?).to be false
      end
    end

    context "when user has not set up 2FA" do
      context "and user has 2FA mandated" do
        it "is true" do
          expect(user.prompt_for_2fa?).to be true
        end
      end

      context "and user does not have 2FA mandated" do
        before do
          user.update!(require_2fa: false)
        end

        it "is false" do
          expect(user.prompt_for_2fa?).to be false
        end
      end
    end
  end

  describe "#has_2fa?" do
    it "is true when otp_secret is present" do
      user.update!(otp_secret: "a secret")
      expect(user.has_2fa?).to be true
    end

    it "is false when otp_secret is not present" do
      expect(user.has_2fa?).to be false
    end
  end

  describe "#reset_2fa!" do
    before do
      user.update!(otp_secret: "a secret", require_2fa: false)
    end

    it "blanks otp_secret" do
      user.reset_2fa!
      expect(user.otp_secret).to be_nil
    end

    it "sets require_2fa to true" do
      user.reset_2fa!
      expect(user.require_2fa?).to be true
    end
  end

  describe "#manageable_roles" do
    it "returns roles that the user is allowed to manage" do
      expect(user.manageable_roles).to be_empty
      expect(admin_user.manageable_roles).to match_array(%w[normal admin])
    end
  end

  describe "#invited_but_not_yet_accepted?" do
    it "is true when invitation is sent and user has not yet accepted" do
      expect(invited_user.invited_but_not_yet_accepted?).to be true
    end

    it "is false when invitation is sent and user has accepted" do
      expect(active_user.invited_but_not_yet_accepted?).to be false
    end

    it "is false when invitation not sent" do
      expect(user.invited_but_not_yet_accepted?).to be false
    end
  end

  describe "#unusable_account?" do
    it "is true when invitation is sent and user has not yet accepted" do
      expect(invited_user.unusable_account?).to be true
    end

    it "is true when user is suspended" do
      expect(suspended_user.unusable_account?).to be true
    end

    it "is true when user is locked out" do
      expect(locked_user.unusable_account?).to be true
    end

    it "is false when user has accepted invite, is not suspended and is not locked out" do
      expect(active_user.unusable_account?).to be false
    end
  end

  describe "#status" do
    it "is 'invited' when user has been invited but has not yet accepted" do
      expect(invited_user.status).to eql described_class::USER_STATUS_INVITED
    end

    it "is 'active' when api user has been invited but has not yet accepted" do
      invited_user.update!(api_user: true)
      expect(invited_user.status).to eql described_class::USER_STATUS_ACTIVE
    end

    it "is 'suspended' when user has been suspended" do
      expect(suspended_user.status).to eql described_class::USER_STATUS_SUSPENDED
    end

    it "is 'locked' when user has been locked out" do
      expect(locked_user.status).to eql described_class::USER_STATUS_LOCKED
    end

    it "is 'active' when user has accepted invite, is not suspended and is not locked out" do
      expect(active_user.status).to eql described_class::USER_STATUS_ACTIVE
    end
  end
end
