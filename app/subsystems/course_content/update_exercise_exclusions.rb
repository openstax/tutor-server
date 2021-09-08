class CourseContent::UpdateExerciseExclusions
  lev_routine transaction: :read_committed, express_output: :exercise_representations

  uses_routine GetExercises, as: :get_exercises

  protected

  def exec(course:, updates_array:)
    updates_array = updates_array.map(&:stringify_keys)
    exercise_ids = updates_array.map { |update| update['id'] }
    exercises_by_id = Content::Models::Exercise.where(id: exercise_ids).index_by { |ex| ex.id.to_s }

    # The course is touched at the end, so we lock the course to make this update atomic
    course.lock!

    course_id = course.id

    excluded_exercises = []
    unexcluded_exercise_numbers = []
    outputs[:exercise_representations] = updates_array.map do |exercise_params|
      fatal_error(code: :id_blank, message: 'Missing id for exercise exclusion') \
        unless exercise_params.has_key?('id')
      fatal_error(
        code: :is_excluded_blank, message: "Missing is_excluded for exercise with 'id'=#{id}"
      ) unless exercise_params.has_key?('is_excluded')

      id = exercise_params.fetch('id').to_s
      exercise = exercises_by_id[id]
      fatal_error(
        code: :exercise_not_found,
        message: "Couldn't find Content::Models::Exercise with 'id'=#{id}"
      ) if exercise.nil?

      is_excluded = !!exercise_params.fetch('is_excluded')

      if is_excluded
        excluded_exercises << CourseContent::Models::ExcludedExercise.new(
          course_profile_course_id: course_id, exercise_number: exercise.number
        )
      else
        unexcluded_exercise_numbers << exercise.number
      end

      Api::V1::ExerciseRepresenter.new(exercise).to_hash.tap do |exercise_representation|
        exercise_representation['is_excluded'] = !!is_excluded
      end
    end

    CourseContent::Models::ExcludedExercise.import(
      excluded_exercises,
      validate: false,
      on_duplicate_key_ignore: { conflict_target: [ :course_profile_course_id, :exercise_number ] }
    )

    CourseContent::Models::ExcludedExercise.where(
      course_profile_course_id: course_id, exercise_number: unexcluded_exercise_numbers
    ).delete_all

    # This touch ensures that transactions trying to lock the same course will retry
    course.touch
  end
end
