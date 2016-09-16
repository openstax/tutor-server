class CoursesEnroll
  lev_handler

  uses_routine CourseMembership::GetPeriod, as: :get_period,       translations: { outputs: { type: :verbatim } }
  uses_routine CollectCourseInfo,           as: :get_course_info,  translations: { outputs: { type: :verbatim } }
  uses_routine UserIsCourseStudent,         as: :is_student,       translations: { outputs: { type: :verbatim } }
  uses_routine GetUserCourses,              as: :get_courses
  protected

  def authorized?; true; end

  def handle
    run(:get_period, enrollment_code: params[:enroll_token])
    fatal_error(code: :enrollment_code_not_found) if outputs.period.nil?

    run(:get_course_info, with: [:teacher_names], courses: outputs.period.course)
    outputs.course = outputs.courses.first

    outputs.current_courses = run(:get_courses, user: caller).outputs.courses.reject{|c| c.id == outputs.period.course.id }

    run(:is_student, course: outputs.period.course, user: caller,
        include_dropped: true, include_archived: false)

    fatal_error(code: :period_is_archived) if outputs.period.deleted?
    fatal_error(code: :user_is_dropped)    if outputs.is_dropped

    fatal_error(code: :user_is_already_a_course_student) \
               if outputs.user_is_course_student && !outputs.is_dropped
  end

end
