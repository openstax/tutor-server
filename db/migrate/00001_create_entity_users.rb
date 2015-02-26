class CreateEntityUsers < ActiveRecord::Migration
  def change
    create_table :entity_users do |t|
      t.timestamps null: false
    end
  end
end
