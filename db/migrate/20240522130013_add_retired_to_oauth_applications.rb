class AddRetiredToOauthApplications < ActiveRecord::Migration[7.0]
  def change
    add_column :oauth_applications, :retired, :boolean, default: false
  end
end
