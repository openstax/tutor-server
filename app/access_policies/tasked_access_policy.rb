class TaskedAccessPolicy
  def self.action_allowed?(action, requestor, tasked)
    case action
    when :read
      return false unless requestor.is_human?
      return true if DoesTaskingExist.call(task_component: tasked, user: requestor) &&
                     tasked.task_step.task.past_open?
      period = tasked.task_step.task.taskings.first.try(:period)
      return false if period.nil?
      UserIsCourseTeacher.call(user: requestor, course: period.course)
    when :update, :mark_completed, :recover, :refresh
      requestor.is_human? &&
      DoesTaskingExist.call(task_component: tasked, user: requestor) &&
      tasked.task_step.task.past_open?
    else
      false
    end
  end
end
