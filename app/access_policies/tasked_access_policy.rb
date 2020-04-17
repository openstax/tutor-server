class TaskedAccessPolicy
  def self.action_allowed?(action, requestor, tasked)
    return false unless requestor.is_human?
    task = tasked.task_step.task
    case action
    when :read
      return true if DoesTaskingExist[task_component: tasked, user: requestor] && task.past_open?
      period = task.taskings.first&.period
      return false if period.nil?
      UserIsCourseTeacher[user: requestor, course: period.course]
    when :update
      DoesTaskingExist[task_component: tasked, user: requestor] &&
        !task.withdrawn? &&
        !task.past_close? &&
        (task.past_open? || task.roles.first.teacher_student?)
    when :grade
      return false if !task.past_due?
      period = task.taskings.first&.period
      return false if period.nil?
      UserIsCourseTeacher[user: requestor, course: period.course]
    else
      false
    end
  end
end
