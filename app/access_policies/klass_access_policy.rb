class KlassAccessPolicy
  # Contains all the rules for which requestors can do what with which Klass objects.

  def self.action_allowed?(action, requestor, klass)
    case action
    when :read # Anyone (non-anonymous) as long as the class is visible,
               # otherwise educators, course managers and school managers
      !requestor.is_anonymous? && \
      (klass.visible_at < Time.now && klass.invisible_at > Time.now) || \
      (requestor.educators.where(klass_id: klass.id).exists? || \
       requestor.course_managers.where(course_id: klass.course_id).exists? || \
       requestor.school_managers.where(school_id: klass.course.school_id).exists?)
    when :create, :destroy # Course managers and school managers
      !requestor.is_anonymous? && requestor.is_human? && \
      (requestor.course_managers.where(course_id: klass.course_id).exists? || \
       requestor.school_managers.where(school_id: klass.course.school_id).exists?)
    when :update # Educators, course managers and school managers
      !requestor.is_anonymous? && requestor.is_human? && \
      (requestor.educators.where(klass_id: klass.id).exists? || \
       requestor.course_managers.where(course_id: klass.course_id).exists? || \
       requestor.school_managers.where(school_id: klass.course.school_id).exists?)
    else
      false
    end
  end

end
