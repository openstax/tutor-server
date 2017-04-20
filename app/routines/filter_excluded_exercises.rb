class FilterExcludedExercises

  lev_routine express_output: :exercises

  def exec(exercises:, course: nil, additional_excluded_numbers: [])
    admin_exclusions = Settings::Exercises.excluded_ids.split(',').map(&:strip)
    admin_excluded_ids, admin_excluded_numbers = admin_exclusions.partition{ |ex| ex.include? '@' }

    course_excluded_numbers = course.nil? ? [] : course.excluded_exercises.map(&:exercise_number)

    excluded_exercise_numbers_set = Set.new(
      admin_excluded_numbers.map(&:to_i) +
      course_excluded_numbers +
      additional_excluded_numbers.to_a
    )

    admin_excluded_ids_set = Set.new admin_excluded_ids

    outputs[:exercises] = exercises.reject do |ex|
      excluded_exercise_numbers_set.include?(ex.number) || admin_excluded_ids_set.include?(ex.uid)
    end
  end

end
