class UsersPermission < ApplicationRecord
  # associations
  belongs_to :user
  belongs_to :permission
end
