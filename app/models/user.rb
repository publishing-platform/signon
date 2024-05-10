class User < ApplicationRecord
  include Roles

  self.include_root_in_json = true

  MAX_2FA_DRIFT_SECONDS = 30
  REMEMBER_2FA_SESSION_FOR = 30.days

  USER_STATUS_SUSPENDED = "suspended".freeze
  USER_STATUS_INVITED = "invited".freeze
  USER_STATUS_LOCKED = "locked".freeze
  USER_STATUS_ACTIVE = "active".freeze
  USER_STATUSES = [USER_STATUS_SUSPENDED,
                   USER_STATUS_INVITED,
                   USER_STATUS_LOCKED,
                   USER_STATUS_ACTIVE].freeze

  devise :database_authenticatable,
         :recoverable,
         :trackable,
         :validatable,
         :timeoutable,
         :lockable,
         :confirmable,
         :invitable,
         :suspendable # in signon/lib/devise/models/suspendable.rb

  encrypts :otp_secret

  # validation
  validates :name, presence: true
  validates :reason_for_suspension, presence: true, if: proc { |u| u.suspended? }

  # associations
  # belongs_to :organisation, optional: true
  # has_many :users_permissions
  # has_many :permissions, through: :users_permissions

  # hooks
  after_initialize :generate_uid

  def generate_uid
    self.uid ||= UUID.generate
  end

  def prompt_for_2fa?
    return false if has_2fa?

    require_2fa?
  end

  def has_2fa?
    otp_secret.present?
  end

  def authenticate_otp(code)
    totp = ROTP::TOTP.new(otp_secret)
    totp.verify(code, drift_behind: MAX_2FA_DRIFT_SECONDS)
  end

  def manageable_roles
    "Roles::#{role.camelize}".constantize.manageable_roles
  end

  def invited_but_not_yet_accepted?
    invitation_sent_at.present? && invitation_accepted_at.nil?
  end

  def unusable_account?
    invited_but_not_yet_accepted? || suspended? || access_locked?
  end

  def status
    if suspended?
      USER_STATUS_SUSPENDED
    elsif invited_but_not_yet_accepted?
      USER_STATUS_INVITED
    elsif access_locked?
      USER_STATUS_LOCKED
    else
      USER_STATUS_ACTIVE
    end
  end
end
