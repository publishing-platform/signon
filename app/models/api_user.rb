class ApiUser < User
  default_scope { where(api_user: true).order(:name) }
end
