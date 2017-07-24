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
           time_zone: nil, default_open_time: nil, default_due_time: nil, estimated_student_count: nil)

    attrs = {
      name: name || course.name,
      is_college: is_college.nil? ? course.is_college : is_college,
      is_concept_coach: course.is_concept_coach,
      term: term || course.term,
      year: year || course.year + 1,
      num_sections: num_sections || course.num_sections,
      school: course.school,
      catalog_offering: course.offering,
      # don't copy `does_cost` from the course, because that course may not have cost but this one should
      does_cost: course.offering.does_cost,
      appearance_code: course.appearance_code,
      time_zone: time_zone || course.time_zone,
      default_open_time: default_open_time || course.default_open_time,
      default_due_time: default_due_time || course.default_due_time,
      cloned_from: course,
      estimated_student_count: estimated_student_count,
      is_preview: false
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
