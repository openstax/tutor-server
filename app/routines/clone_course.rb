class CloneCourse
  lev_routine express_output: :course

  uses_routine CreateCourse,
               translations: { outputs: { type: :verbatim } },
               as: :create_course

  uses_routine AddUserAsCourseTeacher,
               translations: { outputs: { type: :verbatim } },
               as: :add_teacher

  protected

  def exec(course:, teacher_user:, copy_question_library:,
           name: nil, is_college: nil, term: nil, year: nil, num_sections: nil,
           timezone: nil, estimated_student_count: nil)
    attrs = {
      name: name || course.name,
      is_college: is_college.nil? ? course.is_college : is_college,
      is_concept_coach: course.is_concept_coach,
      is_test: teacher_user.is_test || course.is_test,
      term: term || course.term,
      year: year || course.year + 1,
      num_sections: num_sections || course.num_sections,
      school: course.school,
      catalog_offering: course.offering,
      # don't copy `does_cost` from the course,
      # because that course may not have cost but this one should
      does_cost: course.offering.does_cost,
      appearance_code: course.appearance_code,
      timezone: timezone || course.timezone,
      cloned_from: course,
      estimated_student_count: estimated_student_count,
      is_preview: false,
      reading_weight: course.reading_weight,
      homework_weight: course.homework_weight,
      grading_templates: course.grading_templates.map do |grading_template|
        grading_template.dup.tap { |clone| clone.cloned_from = grading_template }
      end,
      past_due_unattempted_ungraded_wrq_are_zero: course.past_due_unattempted_ungraded_wrq_are_zero
    }

    run(:create_course, attrs)

    run(:add_teacher, course: outputs.course, user: teacher_user)

    if copy_question_library
      course.excluded_exercises.each do |ex|
        outputs.course.excluded_exercises << CourseContent::Models::ExcludedExercise.new(
          course: outputs.course, exercise_number: ex.exercise_number
        )
      end
    end
  end
end
