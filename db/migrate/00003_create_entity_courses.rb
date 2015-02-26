class CreateEntityCourses < ActiveRecord::Migration
  def change
    create_table :entity_courses do |t|
      t.timestamps null: false
    end
  end
end
