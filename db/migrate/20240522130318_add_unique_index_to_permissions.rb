class AddUniqueIndexToPermissions < ActiveRecord::Migration[7.1]
  def change
    add_index(:permissions, %i[oauth_application_id name], unique: true)
  end
end
