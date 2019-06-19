class TeacherStudentAccessPolicy
  def self.action_allowed?(action, requestor, teacher_student)
    return false if !requestor.is_human? || requestor.is_anonymous?

    case action
    when :show
      UserIsCourseTeacher[user: requestor, course: teacher_student.course] &&
        !teacher_student.period.nil? &&
        !teacher_student.period.archived?
    else
      false
    end
  end
end
