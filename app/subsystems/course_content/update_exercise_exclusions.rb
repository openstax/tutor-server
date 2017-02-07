class CourseContent::UpdateExerciseExclusions

  lev_routine express_output: :exercise_representations

  protected

  def exec(course:, updates_array:)

    updates_array = updates_array.map(&:stringify_keys)
    page_ids = Content::Models::Exercise.find(updates_array.map{ |update| update['id'] })
                                        .map(&:content_page_id)

    # The course's biglearn_excluded_pool is updated at the end,
    # so we can just lock the course to make this update atomic
    course.lock!

    out = GetExercises.call(course: course, page_ids: page_ids).outputs
    exercises = out.exercises.index_by{ |ex| ex.id.to_s }
    page_exercises = out.exercise_search['items'].index_by(&:id)

    outputs[:exercise_representations] = updates_array.map do |exercise_params|
      id = exercise_params['id']
      is_excluded = exercise_params['is_excluded']

      exercise = exercises[id]
      exercise_representation = page_exercises[id]

      if is_excluded # true
        CourseContent::Models::ExcludedExercise.find_or_create_by(
          course_profile_course_id: course.id, exercise_number: exercise.number
        )
        exercise_representation['is_excluded'] = true
      elsif !is_excluded.nil? # false
        excluded_exercise = CourseContent::Models::ExcludedExercise.find_by(
          course_profile_course_id: course.id, exercise_number: exercise.number
        ).try(:destroy)
        exercise_representation['is_excluded'] = false
      end

      exercise_representation
    end

    # This touch ensures that transactions trying to lock the same course will retry
    course.touch

    # Send the exercise exclusions to Biglearn
    OpenStax::Biglearn::Api.update_course_exercise_exclusions(course: course)

  end

end
