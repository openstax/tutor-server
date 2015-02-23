class CreateEntitySsRoles < ActiveRecord::Migration
  def change
    create_table :entity_ss_roles do |t|
      t.timestamps null: false
    end
  end
end
