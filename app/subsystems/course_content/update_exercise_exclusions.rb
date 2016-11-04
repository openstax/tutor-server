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

    # Create a new Biglearn excluded pool for the course
    excluded_exercise_numbers = CourseContent::Models::ExcludedExercise
                                  .where(course_profile_course_id: course.id)
                                  .pluck(:exercise_number)
    exercises_base_url = Addressable::URI.parse(OpenStax::Exercises::V1.server_url)
    exercises_base_url.scheme = nil
    exercises_base_url.path = 'exercises'
    excluded_exercise_question_ids = excluded_exercise_numbers.map do |number|
      "#{exercises_base_url}/#{number}"
    end
    bl_excluded_exercises = excluded_exercise_question_ids.map do |question_id|
      # version 1 is the default according to the Biglearn API docs...
      # what we really want here is to exclude all versions
      OpenStax::Biglearn::V1::Exercise.new(question_id: question_id, version: 1, tags: [])
    end
    bl_excluded_pool = OpenStax::Biglearn::V1::Pool.new(exercises: bl_excluded_exercises)
    bl_excluded_pool_with_uuid = OpenStax::Biglearn::V1.add_pools([bl_excluded_pool]).first

    # This update ensures that transactions trying to lock the same course will retry
    course.update_attribute(:biglearn_excluded_pool_uuid, bl_excluded_pool_with_uuid.uuid)

  end

end
