class CreateEntityRoles < ActiveRecord::Migration[4.2]
  def change
    create_table :entity_roles do |t|
      t.integer :role_type, null: false, default: 0

      t.timestamps null: false

      t.index :role_type
    end
  end
end
