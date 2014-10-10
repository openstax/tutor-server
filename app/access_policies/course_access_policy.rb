class CourseAccessPolicy
  # Contains all the rules for which requestors can do what with which Course objects.

  def self.action_allowed?(action, requestor, course)
    case action
    when :read # Anyone (non-anonymous)
      !requestor.is_anonymous?
    when :create, :destroy # School managers
      !requestor.is_anonymous? && requestor.is_human? && \
      requestor.school_managers.where(school_id: course.school_id).exists?
    when :update # Course managers and school managers
      !requestor.is_anonymous? && requestor.is_human? && \
      (requestor.course_managers.where(course_id: course.id).exists? || \
       requestor.school_managers.where(school_id: course.school_id).exists?)
    else
      false
    end
  end

end
