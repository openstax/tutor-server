class CreateSchools < ActiveRecord::Migration
  def change
    create_table :schools do |t|
      t.string :name
      t.string :default_time_zone

      t.timestamps null: false
    end
  end
end
