class AddApiUserToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :api_user, :boolean, null: false, default: false
  end
end
