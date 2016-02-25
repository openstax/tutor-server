class CreateCourseContentExerciseOptions < ActiveRecord::Migration
  def change
    create_table :course_content_exercise_options do |t|
      t.references :entity_course_id,
                   index: {
                     name: 'index_course_content_exercise_options_on_course_id'
                   }
      t.string :exercise_uid, index: true
      t.boolean :is_excluded, default: false

      t.timestamps null: false
    end
  end
end
