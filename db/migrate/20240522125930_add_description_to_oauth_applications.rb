class AddDescriptionToOauthApplications < ActiveRecord::Migration[7.1]
  def change
    add_column :oauth_applications, :description, :string
  end
end
