class CreateReadings < ActiveRecord::Migration
  def change
    create_table :readings do |t|
      t.timestamps null: false
    end
  end
end
