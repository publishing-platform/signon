class Permission < ApplicationRecord
  SIGNIN_NAME = "signin".freeze

  # validation
  validates :name, presence: true, uniqueness: { scope: :oauth_application_id }
  validate :signin_permission_name_not_changed

  # associations
  has_many :users_permissions
  has_many :users, through: :users_permissions
  belongs_to :oauth_application

  # scopes
  default_scope { order(:name) }
  scope :signin, -> { where(name: SIGNIN_NAME) }

  def signin?
    name.try(:downcase) == SIGNIN_NAME
  end

private

  def signin_permission_name_not_changed
    return if new_record? || !name_changed?

    if name_was == SIGNIN_NAME
      errors.add(:name, "of permission #{name_was} can't be changed")
    end
  end
end
