class AddTypeToEntityRoles < ActiveRecord::Migration
  def change
    add_column :entity_roles, :role_type, :integer, null: false, default: 0
    add_index :entity_roles, :role_type
  end
end
