class CreateEntityCourses < ActiveRecord::Migration[4.2]
  def change
    create_table :entity_courses do |t|
      t.timestamps null: false
    end
  end
end
