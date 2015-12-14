class TaskAccessPolicy
  def self.action_allowed?(action, requestor, task)
    case action
    when :read
      requestor.is_human? && (
        (
          DoesTaskingExist.call(task_component: task, user: requestor) &&
          task.past_open?
        ) || (
          (course = get_entity_course(task)) && UserIsCourseTeacher.call(user: requestor, course: course)
        )
      )
    else
      false
    end
  end

  def self.get_entity_course(task)
    course = task.task_plan.try(:owner) ||  # normal course
             task.concept_coach_task.task.taskings.first.try(:period).try(:course) # cc course
    course.is_a?(Entity::Course) ? course : nil
  end

end
