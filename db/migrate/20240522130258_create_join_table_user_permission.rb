class CreateJoinTableUserPermission < ActiveRecord::Migration[7.1]
  def change
    create_join_table :users, :permissions, table_name: "users_permissions", column_options: { null: false, foreign_key: true } do |t|
      t.index %i[user_id permission_id]
      t.index %i[permission_id user_id]
    end
  end
end
