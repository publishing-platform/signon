class AddApiOnlyToOauthApplications < ActiveRecord::Migration[7.1]
  def change
    add_column :oauth_applications, :api_only, :boolean, default: false, null: false
  end
end
