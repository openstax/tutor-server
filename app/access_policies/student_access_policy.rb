class StudentAccessPolicy
  # Contains all the rules for which requestors can do what with which Student objects.

  def self.action_allowed?(action, requestor, student)
    case action
    when :index # Anyone (non-anonymous) - `read` is also applied to each record
      !requestor.is_anonymous? && requestor.is_human?
    when :read, :destroy
      # The user himself, educators, course managers, school managers and administrators
      !requestor.is_anonymous? && requestor.is_human? && \
      (requestor.id == student.user_id || \
       requestor.educators.where(klass_id: student.klass_id).exists? || \
       requestor.course_managers.where(course_id: student.klass.course_id).exists? || \
       requestor.school_managers.where(school_id: student.course.school_id).exists? || \
       !!requestor.administrator)
    when :create, :update # Educators, course managers, school managers and administrators
      !requestor.is_anonymous? && requestor.is_human? && \
      (requestor.educators.where(klass_id: student.klass_id).exists? || \
       requestor.course_managers.where(course_id: student.klass.course_id).exists? || \
       requestor.school_managers.where(school_id: student.course.school_id).exists? || \
       !!requestor.administrator)
    else
      false
    end
  end

end
