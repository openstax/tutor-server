class GetTeacherNames
  lev_routine express_output: :teacher_names

  uses_routine GetCourseTeacherUsers,
    translations: { outputs: { type: :verbatim } },
    as: :get_teacher_users

  protected

  def exec(course_id)
    course = CourseProfile::Models::Course.find(course_id)
    run(:get_teacher_users, course)
    outputs[:teacher_names] = outputs[:teachers].map(&:name).sort
  end
end
