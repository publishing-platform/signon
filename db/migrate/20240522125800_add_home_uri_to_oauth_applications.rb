class AddHomeUriToOauthApplications < ActiveRecord::Migration[7.0]
  def change
    add_column :oauth_applications, :home_uri, :string
  end
end
