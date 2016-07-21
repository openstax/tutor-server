class GetExercises

  lev_routine express_output: :exercise_search, transaction: :no_transaction

  uses_routine GetCourseEcosystem, as: :get_ecosystem
  uses_routine FilterExcludedExercises, as: :filter

  # Returns Content::Exercises filtered "by":
  #   :ecosystem or :course
  #   :page_ids (defaults to all)
  #   :pool_types (defaults to all)
  #
  # returns course-specific exclusion information with the exercises (if :course provided)

  def exec(ecosystem: nil, course: nil, page_ids: nil, pool_types: nil)
    raise ArgumentError, "Either :ecosystem or :course must be provided" \
      if ecosystem.nil? && course.nil?

    ecosystem ||= run(:get_ecosystem, course: course).outputs.ecosystem

    pools_map = GetEcosystemPoolsByPageIdsAndPoolTypes[ecosystem: ecosystem,
                                                       page_ids: page_ids,
                                                       pool_types: pool_types]

    excl_exercise_numbers_set = Set.new(course.excluded_exercises.pluck(:exercise_number)) \
      unless course.nil?

    all_exercises = []

    # Build map of exercise uids to representations, with pool type
    exercise_representations = pools_map.each_with_object({}) do |(pool_type, pools), hash|
      pool_exercises = pools.flat_map{ |pool| pool.exercises(preload: [:page, {tags: :teks_tags}]) }
      exercises = run(:filter, exercises: pool_exercises).outputs.exercises

      exercises.each do |exercise|
        unless hash.has_key?(exercise.uid)
          hash[exercise.uid] = Api::V1::ExerciseRepresenter.new(exercise).to_hash
          hash[exercise.uid]['pool_types'] = []
          hash[exercise.uid]['is_excluded'] = excl_exercise_numbers_set.include?(exercise.number) \
            unless course.nil?
        end

        hash[exercise.uid]['pool_types'] << pool_type
      end

      all_exercises += exercises
    end

    outputs[:exercises] = all_exercises.uniq
    outputs[:exercise_search] = Hashie::Mash.new(items: exercise_representations.values)
  end

end
