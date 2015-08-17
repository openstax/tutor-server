class DistributeTasks

  lev_routine

  uses_routine IndividualizeTaskingPlans,
               translations: { outputs: { type: :verbatim } },
               as: :get_tasking_plans

  protected
  def exec(task_plan)
    task_plan.lock!
    delete_pre_existing_assignments(task_plan)
    run(:get_tasking_plans, task_plan)

    entity_tasks = set_taskings(task_plan)

    Entity::Task.import!(entity_tasks, recursive: true)

    if task_plan.persisted?
      task_plan.update_column(:published_at, Time.current)
    end

    outputs[:entity_tasks] = entity_tasks
  end

  def set_taskings(task_plan)
    entity_tasks = task_plan.assistant.build_tasks(task_plan: task_plan,
                                                   taskees: taskees)

    entity_tasks.each_with_index do |entity_task, i|
      role = taskees[i]

      entity_task.taskings << Tasks::Models::Tasking.new(
                                task: entity_task,
                                role: role,
                                period: role.student.try(:period)
                              )

      set_task_dates(entity_task.task, i)
      save_taskeds_without_saving_task_steps(entity_task)
      entity_task.task.update_step_counts
    end

    entity_tasks
  end

  def set_task_dates(task, i)
    task.opens_at = opens_ats[i]
    task.due_at = due_ats[i] || (task.opens_at + 1.week)
    task.feedback_at ||= task.due_at
  end

  def taskees
    outputs.tasking_plans.collect(&:target)
  end

  def opens_ats
    outputs.tasking_plans.collect(&:opens_at)
  end

  def  due_ats
    outputs.tasking_plans.collect(&:due_at)
  end

  def delete_pre_existing_assignments(task_plan)
    if task_plan.tasks.any?
      task_plan.tasks.flat_map(&:entity_task).each(&:destroy)
    end
  end

  # Because it's slow if task_steps are saved with taskeds, and
  # Taskeds can't be saved in Entity::Task.import!
  def save_taskeds_without_saving_task_steps(entity_task)
    entity_task.task.task_steps.each_with_index do |task_step, index|
      tasked = task_step.tasked
      tasked.task_step = nil

      tasked.save!

      task_step.tasked = tasked
      task_step.number = index + 1
    end
  end
end
