class DistributeTasks

  lev_routine

  uses_routine IndividualizeTaskingPlans, as: :get_tasking_plans

  protected

  def exec(task_plan)
    task_plan.publish_last_requested_at = Time.now

    assistant = task_plan.assistant

    # Abort Task creation early if task_plan is invalid
    transfer_errors_from(task_plan, { type: :verbatim }, true) unless task_plan.valid?

    # Delete pre-existing assignments
    task_plan.tasks.destroy_all unless task_plan.tasks.empty?

    tasking_plans = run(:get_tasking_plans, task_plan).outputs.tasking_plans

    taskees = tasking_plans.collect { |tp| tp.target }
    opens_ats = tasking_plans.collect { |tp| tp.opens_at }
    due_ats = tasking_plans.collect { |tp| tp.due_at }

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
      task.save!
    end

    outputs[:tasks] = tasks

    task_plan.published_at = Time.now
    task_plan.save
  end

end
