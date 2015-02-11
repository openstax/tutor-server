class CreateSchools < ActiveRecord::Migration
  def change
    create_table :schools do |t|
      t.string :name, null: false
      t.string :default_time_zone

      t.timestamps null: false
    end

    add_index :schools, :name, unique: true
  end
end
