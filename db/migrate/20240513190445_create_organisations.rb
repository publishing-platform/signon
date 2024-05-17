class CreateOrganisations < ActiveRecord::Migration[7.0]
  def change
    create_table :organisations do |t|
      t.string :content_id, null: false
      t.string :slug, null: false
      t.string :name, null: false
      t.string :organisation_type, null: false
      t.string :abbreviation
      t.boolean :closed, default: false

      t.timestamps
    end

    add_index :organisations, :slug, unique: true
    add_index :organisations, :content_id, unique: true
  end
end
