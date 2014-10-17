class CourseAccessPolicy
  # Contains all the rules for which requestors can do what with which Course objects.

  def self.action_allowed?(action, requestor, course)
    case action
    when :index, :read # Anyone (non-anonymous)
      !requestor.is_anonymous?
    when :create, :destroy # School managers and administrators
      !requestor.is_anonymous? && requestor.is_human? && \
      (requestor.school_managers.where(school_id: course.school_id).exists? || \
       !!requestor.administrator)
    when :update # Course managers, school managers and administrators
      !requestor.is_anonymous? && requestor.is_human? && \
      (requestor.course_managers.where(course_id: course.id).exists? || \
       requestor.school_managers.where(school_id: course.school_id).exists? || \
       !!requestor.administrator)
    else
      false
    end
  end

end
