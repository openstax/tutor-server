class DistributeTasks

  lev_routine

  uses_routine IndividualizeTaskingPlans, as: :get_tasking_plans

  protected

  def save(tasks)
    tasks.each do |task|
      task.task_steps.each_with_index do |task_step, index|
        tasked = task_step.tasked
        tasked.task_step = nil
        tasked.save!
        task_step.tasked = tasked
        task_step.number = index + 1
      end

      task.update_step_counts
    end

    Tasks::Models::Task.import! tasks, recursive: true

    tasks.each do |task|
      task.task_steps.reset
      task.tasked_exercises.reset
      task.taskings.reset
    end
  end

  def exec(task_plan, publish_time = Time.current, protect_unopened_tasks = false)
    task_plan.lock!

    fatal_error(code: :publish_last_requested_at_must_be_in_the_past) \
      if task_plan.publish_last_requested_at.present? &&
         task_plan.publish_last_requested_at > publish_time

    tasks = task_plan.tasks.preload(taskings: :role)

    # Delete pre-existing assignments only if
    # no assignments are open and protect_unopened_tasks is false
    tasks.each(&:really_destroy!) \
      if !protect_unopened_tasks &&
         tasks.none?{ |task| task.past_open?(current_time: publish_time) }

    tasked_taskees = tasks.reject(&:destroyed?)
                          .flat_map{ |task| task.taskings.map(&:role) }

    tasking_plans = run(:get_tasking_plans, task_plan).outputs.tasking_plans

    taskees = tasking_plans.map(&:target)
    opens_ats = tasking_plans.map(&:opens_at)
    due_ats = tasking_plans.map(&:due_at)
    time_zones = tasking_plans.map(&:time_zone)

    # Exclude students that already had the assignment
    untasked_taskees = taskees - tasked_taskees

    assistant = task_plan.assistant

    # Call the assistant code to create Tasks, then distribute them
    tasks = assistant.build_tasks(task_plan: task_plan, taskees: untasked_taskees)
    fatal_error(code: :empty_tasks,
                message: 'Tasks could not be published because some tasks were empty') \
      if tasks.any?{ |task| !task.stepless? && task.task_steps.empty? }
    tasks.each_with_index do |task, ii|
      role = untasked_taskees[ii]
      tasking = Tasks::Models::Tasking.new(
        task: task,
        role: role,
        period: role.student.try(:period)
      )
      task.taskings << tasking
      task.time_zone = time_zones[ii]
      task.opens_at = opens_ats[ii]
      task.due_at = due_ats[ii]
      task.feedback_at = task_plan.is_feedback_immediate ? nil : task.due_at
    end

    save(tasks)

    task_plan.first_published_at = publish_time if task_plan.first_published_at.nil?
    task_plan.last_published_at = publish_time
    task_plan.save! if task_plan.persisted?

    outputs[:tasks] = tasks
  end

end
