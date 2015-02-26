class CreateEntityRoles < ActiveRecord::Migration
  def change
    create_table :entity_roles do |t|
      t.timestamps null: false
    end
  end
end
