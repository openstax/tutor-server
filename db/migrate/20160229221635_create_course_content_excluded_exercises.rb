class CreateCourseContentExcludedExercises < ActiveRecord::Migration
  def change
    create_table :course_content_excluded_exercises do |t|
      t.references :entity_course, null: false
      t.integer    :number,        null: false

      t.timestamps null: false
    end
  end
end
