class GetExercises
  lev_routine transaction: :no_transaction, express_output: :exercise_search

  uses_routine GetCourseEcosystem, as: :get_ecosystem
  uses_routine FilterExcludedExercises, as: :filter
  uses_routine GetPageExerciseIdsByPoolTypes, as: :get_page_exercise_ids

  # Returns Content::Models::Exercises filtered "by":
  #   :ecosystem or :course
  #   :exercise_ids (defaults to all)
  #   :page_ids (defaults to all)
  #   :pool_types (defaults to all)
  #
  # returns course-specific exclusion information with the exercises (if :course provided)
  def exec(
    ecosystem: nil,
    course: nil,
    page_ids: nil,
    exercise_ids: nil,
    pool_types: nil,
    include_deleted: false
  )
    raise ArgumentError, "Either :ecosystem or :course must be provided" \
      if ecosystem.nil? && course.nil?

    ecosystem ||= run(:get_ecosystem, course: course).outputs.ecosystem

    exercise_ids_by_pool_type = run(
      :get_page_exercise_ids,
      ecosystem: ecosystem,
      page_ids: page_ids,
      exercise_ids: exercise_ids,
      pool_types: pool_types
    ).outputs.exercise_ids_by_pool_type

    excl_exercise_numbers_set = Set.new(course.excluded_exercises.pluck(:exercise_number)) \
      unless course.nil?

    profile_ids = [User::Models::OpenStaxProfile::ID]
    profile_ids << course.related_teacher_profile_ids if course

    # Preload exercises, pages and teks tags
    all_exercises = Content::Models::Exercise
      .where(id: exercise_ids_by_pool_type.values.flatten.uniq)
      .where(user_profile_id: profile_ids.flatten.uniq)
      .preload(:page, tags: :teks_tags)
    all_exercises = all_exercises.not_deleted unless include_deleted
    exercises_by_id = all_exercises.index_by(&:id)

    # Filter excluded exercises only if exercise_ids are not specified
    filter_exercises = exercise_ids.blank?

    # Build map of exercise uids to representations, with pool type
    hash = {}

    exercise_ids_by_pool_type.each do |pool_type, exercise_ids|
      pool_exercises = exercises_by_id.values_at(*exercise_ids).compact

      if filter_exercises
        pool_exercises = run(:filter, exercises: pool_exercises,
                                      profile_ids: profile_ids).outputs.exercises
      end

      pool_exercises.each do |exercise|
        unless hash.has_key?(exercise.uid)
          hash[exercise.uid] = Api::V1::ExerciseRepresenter.new(exercise).to_hash
          hash[exercise.uid]['pool_types'] = []
          hash[exercise.uid]['is_excluded'] = excl_exercise_numbers_set.include?(exercise.number) \
            unless course.nil?
        end

        hash[exercise.uid]['pool_types'] << pool_type
      end
    end

    outputs.exercises = exercises_by_id.values
    outputs.exercise_search = Hashie::Mash.new(items: hash.values)
  end
end
