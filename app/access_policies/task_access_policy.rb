class TaskAccessPolicy
  def self.action_allowed?(action, requestor, task)
    case action
    when :read
      requestor.is_human? && (
        (
          DoesTaskingExist[task_component: task, user: requestor.user] &&
          task.past_open?
        ) ||
        (
          (course = task.task_plan.try(:owner)).is_a?(Entity::Course) &&
          UserIsCourseTeacher[user: requestor.user, course: course]
        )
      )
    else
      false
    end
  end
end
