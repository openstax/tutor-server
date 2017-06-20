class CourseContent::UpdateExerciseExclusions

  lev_routine express_output: :exercise_representations

  uses_routine GetExercises, as: :get_exercises

  protected

  def exec(course:, updates_array:)
    updates_array = updates_array.map(&:stringify_keys)
    exercise_ids = updates_array.map { |update| update['id'] }
    page_ids = Content::Models::Exercise.where(id: exercise_ids).pluck(:content_page_id)

    # The course is touched at the end, so we lock the course to make this update atomic
    course.lock!

    course_id = course.id

    out = run(:get_exercises, course: course, page_ids: page_ids).outputs
    exercises_by_id = out.exercises.index_by { |ex| ex.id.to_s }
    exercise_representations_by_id = out.exercise_search['items'].index_by(&:id)

    excluded_exercises = []
    unexcluded_exercise_numbers = []
    outputs[:exercise_representations] = updates_array.map do |exercise_params|
      fatal_error(:id_blank, 'Missing id for exercise exclusion') \
        unless exercise_params.has_key?('id')
      fatal_error(:is_excluded_blank, "Missing is_exclusion for exercise with 'id'=#{id}") \
        unless exercise_params.has_key?('is_excluded')

      id = exercise_params.fetch('id').to_s
      exercise = exercises_by_id[id]
      exercise_representation = exercise_representations_by_id[id]
      fatal_error(:exercise_not_found, "Couldn't find Content::Models::Exercise with 'id'=#{id}") \
        if exercise.nil? || exercise_representation.nil?

      is_excluded = !!exercise_params.fetch('is_excluded')
      exercise_representation['is_excluded'] = !!is_excluded

      if is_excluded
        excluded_exercises << CourseContent::Models::ExcludedExercise.new(
          course_profile_course_id: course_id, exercise_number: exercise.number
        )
      else
        unexcluded_exercise_numbers << exercise.number
      end

      exercise_representation
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

    # Send the exercise exclusions to Biglearn
    OpenStax::Biglearn::Api.update_course_excluded_exercises(course: course)
  end

end
