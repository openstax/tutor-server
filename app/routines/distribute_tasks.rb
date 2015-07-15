class DistributeTasks

  lev_routine

  uses_routine IndividualizeTaskingPlans, as: :get_tasking_plans

  protected

  def efficiently_save(task)
    steps = task.task_steps.to_a
    task.task_steps = []
    task.save!
    steps.each do |step|
      tasked = step.tasked
      tasked.task_step = nil
      tasked.save!
      step.tasked = tasked
      task.task_steps << step
      step.save!
    end
  end

  def exec(task_plan)
    # Delete pre-existing assignments
    task_plan.tasks.destroy_all unless task_plan.tasks.empty?

    tasking_plans = run(:get_tasking_plans, task_plan).outputs.tasking_plans

    taskees = tasking_plans.collect { |tp| tp.target }
    opens_ats = tasking_plans.collect { |tp| tp.opens_at }
    due_ats = tasking_plans.collect { |tp| tp.due_at }

    assistant = task_plan.assistant

    # Call the assistant code to create Tasks, then distribute them
    tasks = assistant.build_tasks(task_plan: task_plan, taskees: taskees)
    tasks.each_with_index do |task, ii|
      tasking = Tasks::Models::Tasking.new(
        task: task.entity_task,
        role: taskees[ii]
      )
      task.entity_task.taskings << tasking

      task.opens_at = opens_ats[ii]
      task.due_at = due_ats[ii] || (task.opens_at + 1.week)
      task.feedback_at ||= task.due_at
      efficiently_save(task)
    end

    outputs[:tasks] = tasks

    task_plan.update_column(:published_at, Time.now)
  end

end
