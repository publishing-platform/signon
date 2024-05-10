class AddTwoFactorAuthenticationToUsers < ActiveRecord::Migration[7.1]
  def change
    change_table :users, bulk: true do |t|
      t.column :otp_secret, :string
      t.column :require_2fa, :boolean, null: false, default: true
      t.index :otp_secret, unique: true
    end
  end
end
