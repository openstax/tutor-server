class AddUuidToContentExercises < ActiveRecord::Migration
  def change
    add_column :content_exercises, :uuid, :uuid

    all_exercise_numbers = Content::Models::Exercise.pluck(:number)

    all_exercise_numbers.each do |number|
      uuid = OpenStax::Exercises::V1.exercises(number: number).first.uuid ||
             raise('Exercise UUID not found - Migrate Exercises first')
      Content::Models::Exercise.where(number: number).update_all(uuid: uuid)
    end

    change_column_null :content_exercises, :uuid, false

    add_index :content_exercises, [:uuid, :version]
  end
end
