class GetExercises

  lev_routine express_output: :exercises, transaction: :no_transaction

  uses_routine GetCourseEcosystem, as: :get_ecosystem

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

    excluded_exercise_numbers = CourseContent::Models::ExcludedExercise
                                  .where(entity_course_id: course.id)
                                  .pluck(:exercise_number) unless course.nil?

    # Build map of exercise uids to representations, with pool type
    exercise_representations = pools_map.each_with_object({}) do |(pool_type, pools), hash|
      pools.flat_map{ |pool| pool.exercises(preload_tags: true) }.each do |exercise|
        hash[exercise.uid] ||= Api::V1::ExerciseRepresenter.new(exercise).to_hash
        hash[exercise.uid]['pool_types'] ||= []
        hash[exercise.uid]['pool_types'] << pool_type
        hash[exercise.uid]['is_excluded'] = excluded_exercise_numbers.include?(exercise.number) \
          unless course.nil?
      end
    end

    outputs[:exercises] = Hashie::Mash.new(items: exercise_representations.values)
  end

end
