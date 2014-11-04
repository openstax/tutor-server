class AssignDueTaskPlans

  lev_routine

  uses_routine CreateTaskFromTaskPlan, as: :create_task
  uses_routine AssignTask, as: :assign_task

  protected

  def split_assignee(assignee)
    case assignee
    when Klass
      assignee.students
#TODO:    when GroupOfStudents
#TODO:      assignee.students
    else
      assignee
  end

  def exec(options={})
    tps = TaskPlan.due
    tps.each do |tp|
      assistant = tp.prototype_task.klass.try(:assistant_at, tp.assign_after)
      split_assignee(tp.assignee).each do |a|
        assistant.task_plan_due(tp)
        task = run(:create_task, task_plan: tp).outputs[:task]
        assistant.task_created(task)
        assigned_task = run(:assign_task, task: task, assignee: a).outputs[:assigned_task]
        assistant.task_assigned(assigned_task)
      end
    end
  end

end
