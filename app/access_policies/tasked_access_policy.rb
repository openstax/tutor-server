class TaskedAccessPolicy
  def self.action_allowed?(action, requestor, tasked)
    return false unless requestor.is_human?
    task = tasked.task_step.task
    case action
    when :read
      return true if DoesTaskingExist[task_component: tasked, user: requestor] &&
        tasked.task_step.task.past_open?
      period = task.taskings.first.try(:period)
      return false if period.nil?
      UserIsCourseTeacher[user: requestor, course: period.course]
    when :update
      DoesTaskingExist[task_component: tasked, user: requestor] &&
        task.roles.first.teacher_student? || (
          task.past_open? && !task.withdrawn?
        )
    else
      false
    end
  end
end
