class CreateEntityUsers < ActiveRecord::Migration[4.2]
  def change
    create_table :entity_users do |t|
      t.timestamps null: false
    end
  end
end
