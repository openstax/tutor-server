class AddUuidAndGroupUuidToContentExercises < ActiveRecord::Migration
  def change
    add_column :content_exercises, :uuid, :uuid
    add_column :content_exercises, :group_uuid, :uuid

    all_exercise_numbers = Content::Models::Exercise.uniq.pluck(:number)

    all_exercise_numbers.each_slice(1000) do |numbers|
      exercises = OpenStax::Exercises::V1.exercises(number: numbers)

      exercises.each do |exercise|
        uuid = exercise.uuid || raise('Exercise UUID not found - Migrate Exercises first')
        group_uuid = exercise.group_uuid ||
                     raise('Exercise group UUID not found - Migrate Exercises first')

        Content::Models::Exercise.where(number: exercise.number)
                                 .update_all(uuid: uuid, group_uuid: group_uuid)
      end
    end

    change_column_null :content_exercises, :uuid, false
    change_column_null :content_exercises, :group_uuid, false

    add_index :content_exercises, :uuid
    add_index :content_exercises, [:group_uuid, :version]
  end
end
