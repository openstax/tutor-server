class CreateTaskedReadings < ActiveRecord::Migration
  def change
    create_table :tasked_readings do |t|
      t.timestamps null: false
    end
  end
end
