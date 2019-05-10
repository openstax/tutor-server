class CreateCourseContentExcludedExercises < ActiveRecord::Migration[4.2]
  def change
    create_table :course_content_excluded_exercises do |t|
      t.references :entity_course, null: false, index: true
      t.integer :exercise_number, null: false

      t.timestamps null: false
    end

    add_index :course_content_excluded_exercises, [:exercise_number, :entity_course_id],
              name: 'index_excluded_exercises_on_number_and_course_id', unique: true
  end
end
