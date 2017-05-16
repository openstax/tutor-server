class AddUuidAndGroupUuidToContentExercises < ActiveRecord::Migration
  BATCH_SIZE = 1000

  def up
    add_column :content_exercises, :uuid, :uuid
    add_column :content_exercises, :group_uuid, :uuid

    all_exercise_numbers_and_versions = Content::Models::Exercise.uniq.pluck(:number, :version)
    Rails.logger.info { "Total: #{all_exercise_numbers_and_versions.size} unique exercise uid(s)" }
    all_exercise_numbers_and_versions.group_by(&:second).each do |version, ex_numbers_and_versions|
      Rails.logger.info do
        "Migrating #{ex_numbers_and_versions.size} exercise(s) (version #{version})"
      end

      ex_numbers = ex_numbers_and_versions.map(&:first)
      ex_numbers.each_slice(BATCH_SIZE) do |numbers|
        exercises = OpenStax::Exercises::V1.exercises(number: numbers, version: version)

        next if exercises.empty?

        uuid_cases = []
        group_uuid_cases = []
        exercises.each do |exercise|
          uuid = exercise.uuid ||
                 raise('Exercise UUID not found - Migrate OpenStax Exercises first')
          group_uuid = exercise.group_uuid ||
                       raise('Exercise group UUID not found - Migrate OpenStax Exercises first')

          uuid_cases << "WHEN #{exercise.number} THEN '#{uuid}'::uuid"
          group_uuid_cases << "WHEN #{exercise.number} THEN '#{group_uuid}'::uuid"
        end

        set_uuid_query = "\"uuid\" = CASE \"number\" #{uuid_cases.join(' ')} END"
        set_group_uuid_query = "\"group_uuid\" = CASE \"number\" #{group_uuid_cases.join(' ')} END"
        set_query = "#{set_uuid_query}, #{set_group_uuid_query}"

        Content::Models::Exercise.where(number: numbers, version: version).update_all(set_query)
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
      group_uuid = SecureRandom.uuid

      Content::Models::Exercise
        .where(number: missing_exercise_number)
        .update_all("uuid = gen_random_uuid(), group_uuid = '#{group_uuid}'::uuid")
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
