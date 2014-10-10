class StudentAccessPolicy
  # Contains all the rules for which requestors can do what with which Student objects.

  def self.action_allowed?(action, requestor, student)
    case action
    when :read, :destroy # The user himself, educators, course managers and school managers
      !requestor.is_anonymous? && requestor.is_human? && \
      (requestor.id == student.user_id || \
       requestor.educators.where(klass_id: student.klass_id).exists? || \
       requestor.course_managers.where(course_id: student.klass.course_id).exists? || \
       requestor.school_managers.where(school_id: student.course.school_id).exists?)
    when :create, :update # Educators, course managers and school managers
      !requestor.is_anonymous? && requestor.is_human? && \
      (requestor.educators.where(klass_id: student.klass_id).exists? || \
       requestor.course_managers.where(course_id: student.klass.course_id).exists? || \
       requestor.school_managers.where(school_id: student.course.school_id).exists?)
    else
      false
    end
  end

end
