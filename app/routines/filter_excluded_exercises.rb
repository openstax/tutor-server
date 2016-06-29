class FilterExcludedExercises

  lev_routine express_output: :exercises

  def exec(exercises:, course: nil, additional_excluded_numbers: [])
    admin_excluded_uids_set = Set.new Settings::Exercises.excluded_uids.split(',').map(&:strip)
    course_excluded_numbers = course.nil? ? [] : course.excluded_exercises.map(&:exercise_number)
    excluded_exercise_numbers_set = Set.new(course_excluded_numbers + additional_excluded_numbers)

    outputs[:exercises] = exercises.reject do |ex|
      excluded_exercise_numbers_set.include?(ex.number) || admin_excluded_uids_set.include?(ex.uid)
    end
  end

end
