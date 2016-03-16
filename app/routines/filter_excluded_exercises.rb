class FilterExcludedExercises

  lev_routine express_output: :exercises

  def exec(exercises:, course: nil, additional_excluded_numbers: [])
    admin_excluded_uids = Settings::Exercises.excluded_uids.split(',').map(&:strip)
    course_excluded_numbers = course.nil? ? [] : course.excluded_exercises.pluck(:exercise_number)
    excluded_exercise_numbers = course_excluded_numbers + additional_excluded_numbers

    outputs[:exercises] = exercises.reject do |ex|
      ex.number.in?(excluded_exercise_numbers) || ex.uid.in?(admin_excluded_uids)
    end
  end

end
