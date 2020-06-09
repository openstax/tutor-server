class GradingTemplateAccessPolicy
  def self.action_allowed?(action, requestor, grading_template)
    return false if requestor.is_anonymous? || !requestor.is_human?

    # standard_index also checks for read permissions for each record
    return true if action == :index

    if grading_template.course.pre_wrm_scores?
      # Read-only for old courses
      return action == :read && UserIsCourseTeacher[
        user: requestor, course: grading_template.course
      ]
    else
      # standard_nested_create also checks for course update permissions
      return true if action == :create

      return false unless [ :read, :update, :destroy ].include?(action)

      UserIsCourseTeacher[user: requestor, course: grading_template.course]
    end
  end
end
