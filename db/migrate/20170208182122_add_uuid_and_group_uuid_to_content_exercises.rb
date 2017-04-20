class AddUuidAndGroupUuidToContentExercises < ActiveRecord::Migration
  def up
    add_column :content_exercises, :uuid, :uuid
    add_column :content_exercises, :group_uuid, :uuid

    all_exercise_numbers_and_versions = Content::Models::Exercise.uniq.pluck(:number, :version)
    all_exercise_numbers_and_versions.group_by(&:second).each do |version, ex_numbers_and_versions|
      ex_numbers = ex_numbers_and_versions.map(&:first)
      ex_numbers.each_slice(1000) do |numbers|
        exercises = OpenStax::Exercises::V1.exercises(number: numbers, version: version)

        exercises.each do |exercise|
          uuid = exercise.uuid || raise('Exercise UUID not found - Migrate Exercises first')
          group_uuid = exercise.group_uuid ||
                       raise('Exercise group UUID not found - Migrate Exercises first')

          Content::Models::Exercise.where(number: exercise.number, version: version)
                                   .update_all(uuid: uuid, group_uuid: group_uuid)
        end
      end
    end

    # This happens on QA because we switch between pointing it
    # to exercises-qa and production exercises
    missing_exercise_numbers = Content::Models::Exercise.where(uuid: nil).pluck(:number)
    Rails.logger.error do
      "The following exercise numbers were not found in OpenStax Exercises: #{
      missing_exercise_numbers.join(', ')}"
    end if missing_exercise_numbers.any?
    missing_exercise_numbers.each do |missing_exercise_number|
      uuid = SecureRandom.uuid
      group_uuid = SecureRandom.uuid

      Content::Models::Exercise.where(number: missing_exercise_number)
                               .update_all(uuid: uuid, group_uuid: group_uuid)
    end

    change_column_null :content_exercises, :uuid, false
    change_column_null :content_exercises, :group_uuid, false

    add_index :content_exercises, :uuid
    add_index :content_exercises, [:group_uuid, :version]
  end

  def down
    remove_index :content_exercises, [:group_uuid, :version]
    remove_index :content_exercises, :uuid

    remove_column :content_exercises, :group_uuid
    remove_column :content_exercises, :uuid
  end
end
