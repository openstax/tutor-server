class TaskPlanAccessPolicy
  READ_ONLY_ACTIONS = [ :index, :read ]
  TEACHER_ACTIONS = READ_ONLY_ACTIONS + [ :create, :update, :destroy, :restore ]

  def self.action_allowed?(action, requestor, task_plan)
    return false if requestor.is_anonymous? || !requestor.is_human?

    # All logged in users are allowed to call index
    # The course it is called on will further restrict index permissions
    return true if action == :index

    return false unless TEACHER_ACTIONS.include?(action)

    course = task_plan.course
    is_teacher = UserIsCourseTeacher[user: requestor, course: course]

    if READ_ONLY_ACTIONS.include?(action)
      is_teacher || course.cloned_courses.any? do |clone|
        UserIsCourseTeacher[user: requestor, course: clone]
      end
    else
      is_teacher && !course.ended?
    end
  end
end
