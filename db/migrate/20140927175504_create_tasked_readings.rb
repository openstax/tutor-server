class CreateTaskedReadings < ActiveRecord::Migration
  def change
    create_table :tasked_readings do |t|
      t.string :url, null: false
      t.text :content, null: false
      t.string :title

      t.timestamps null: false
    end
  end
end
