class CreateCourses < ActiveRecord::Migration
  def change
    create_table :courses do |t|
      t.string :name
      t.string :short_name
      t.text :description
      t.references :school

      t.timestamps null: false
    end

    add_index :courses, :school_id
  end
end
