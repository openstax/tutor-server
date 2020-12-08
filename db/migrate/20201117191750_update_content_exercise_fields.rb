class UpdateContentExerciseFields < ActiveRecord::Migration[5.2]
  def up
    change_column :content_exercises, :number, :bigint
    change_column_null :content_exercises, :url, true
    create_sequence :teacher_exercise_number, start: Content::Models::Exercise::TEACHER_NUMBER_START
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
