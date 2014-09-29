class CreateReadings < ActiveRecord::Migration
  def change
    create_table :readings do |t|
      t.references :resource

      t.timestamps null: false
    end

    add_index :readings, :resource_id
  end
end
