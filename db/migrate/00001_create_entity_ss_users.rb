class CreateEntitySsUsers < ActiveRecord::Migration
  def change
    create_table :entity_ss_users do |t|
      t.timestamps null: false
    end
  end
end
