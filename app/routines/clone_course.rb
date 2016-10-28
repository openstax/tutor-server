class CloneCourse

  lev_routine express_output: :course

  uses_routine CreateCourse,
               translations: { outputs: { type: :verbatim } },
               as: :create_course

  uses_routine AddUserAsCourseTeacher,
               translations: { outputs: { type: :verbatim } },
               as: :add_teacher

  protected

  def exec(course:, teacher_user:, copy_question_library:, **attributes)

    attrs = {
      name: course.profile.name,
      term: course.profile.term,
      year: course.profile.year + 1,
      is_college: course.profile.is_college,
      is_concept_coach: course.profile.is_concept_coach,
      num_sections: course.num_sections,
      school: course.profile.school,
      catalog_offering: course.profile.offering,
      appearance_code: course.appearance_code,
      time_zone: course.profile.time_zone
    }.merge(attributes)

    run(:create_course, **attrs)

    run(:add_teacher, course: outputs.course, user: teacher_user)

    if copy_question_library
      course.excluded_exercises.each do |ex|
        outputs.course.excluded_exercises << ExcludedExercise.new(
          course: outputs.course, exercise_number: ex.exercise_number
        )
      end
    end

  end

end
