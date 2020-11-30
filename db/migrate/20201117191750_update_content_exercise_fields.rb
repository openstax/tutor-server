class UpdateContentExerciseFields < ActiveRecord::Migration[5.2]
  def up
    change_column :content_exercises, :number, :bigint
    change_column_null :content_exercises, :url, true
    execute <<-SQL
      CREATE SEQUENCE teacher_exercise_number START 1000000
    SQL
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
