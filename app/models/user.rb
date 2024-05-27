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
  belongs_to :organisation, optional: true
  has_many :users_permissions
  has_many :permissions, through: :users_permissions
  has_many :authorisations, class_name: "Doorkeeper::AccessToken", foreign_key: :resource_owner_id

  # hooks
  after_initialize :generate_uid

  # scopes
  scope :web_users, -> { where(api_user: false) }
  scope :filter_by_name, ->(name) { where("users.email like ? OR users.name like ?", "%#{name.strip}%", "%#{name.strip}%") }
  scope :with_role, ->(role_name) { where(role: role_name) }
  scope :with_organisation, ->(org_id) { where(organisation_id: org_id) }
  scope :with_status, lambda { |status|
    case status
    when USER_STATUS_SUSPENDED
      where.not(suspended_at: nil)
    when USER_STATUS_INVITED
      where.not(invitation_sent_at: nil).where(invitation_accepted_at: nil)
    when USER_STATUS_LOCKED
      where.not(locked_at: nil)
    when USER_STATUS_ACTIVE
      where(suspended_at: nil, locked_at: nil)
        .and(where(invitation_sent_at: nil).or(where.not(invitation_accepted_at: nil)))
    else
      raise NotImplementedError, "Filtering by status '#{status}' not implemented."
    end
  }

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

  def reset_2fa!
    self.otp_secret = nil
    self.require_2fa = true
    save!
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

  def grant_application_signin_permission(application)
    grant_application_permission(application, Permission::SIGNIN_NAME)
  end  

  def grant_application_permission(application, permission_name)
    grant_application_permissions(application, [permission_name]).first
  end

  def grant_application_permissions(application, permission_names)
    return [] if application.retired?

    permission_names.map do |permission_name|
      permission = Permission.find_by(oauth_application_id: application.id, name: permission_name)
      grant_permission(permission)
    end
  end  

  def grant_permission(permission)
    users_permissions.where(permission_id: permission.id).first_or_create!.permission
  end

  def permission_ids_for(application)
    permissions.where(oauth_application_id: application.id).pluck(:id)
  end

  def has_access_to?(application)
    users_permissions.exists?(permission_id: application.signin_permission.id)
  end

  def has_permission?(permission)
    if persisted?
      permissions.exists?(permission.id)
    else
      permissions.any? { |p| p.id == permission.id }
    end
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

  def web_user?
    !api_user?
  end  
end
