class AddDescriptionToOauthApplications < ActiveRecord::Migration[7.0]
  def change
    add_column :oauth_applications, :description, :string
  end
end
