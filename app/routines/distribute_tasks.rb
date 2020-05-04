class DistributeTasks
  lev_routine use_jobba: true

  uses_routine IndividualizeTaskingPlans, as: :individualize_tasking_plans

  protected

  def exec(task_plan:, publish_time: Time.current, protect_unopened_tasks: false, preview: false)
    # Lock the plan to prevent concurrent publication
    task_plan.lock!

    # Abort if it seems like someone already published this plan
    fatal_error(code: :publish_last_requested_at_must_be_in_the_past) \
      if task_plan.publish_last_requested_at.present? &&
         task_plan.publish_last_requested_at > publish_time

    # Get all tasks for this plan
    existing_tasks = task_plan.tasks.preload(taskings: { role: [ :student, :teacher_student ] })

    # Task deletion (re-publishing)
    unless task_plan.out_to_students?(current_time: publish_time)
      # Only delete anything if tasks are not yet available to students
      if preview
        # Delete preview tasks only if no assignments are open
        existing_tasks.select(&:preview?).each(&:really_destroy!)
        existing_tasks = existing_tasks.reject(&:preview?)
      elsif !protect_unopened_tasks
        # Delete pre-existing assignments only if protect_unopened_tasks is false
        existing_tasks.each(&:really_destroy!)
        existing_tasks = []
      end
    end

    # Make a list of all role_ids that still have tasks
    tasks_by_role_id = {}
    existing_tasks.each do |task|
      task.taskings.each { |tasking| tasks_by_role_id[tasking.entity_role_id] = task }
    end

    itp_args = { task_plan: task_plan }

    # If preview is true, only assign to teacher_student roles
    itp_args[:role_type] = :teacher_student if preview

    # Convert tasking_plans to point to individual roles
    tasking_plans = run(:individualize_tasking_plans, itp_args).outputs.tasking_plans

    # Keep only the tasking_plans that point to roles that don't have a task from this plan
    untasked_tasking_plans, tasked_tasking_plans = tasking_plans.partition do |tasking_plan|
      tasks_by_role_id[tasking_plan.target_id].nil?
    end

    assistant = task_plan.assistant

    # Call the assistant code to create Tasks, then distribute them
    new_tasks = assistant.build_tasks(
      task_plan: task_plan, individualized_tasking_plans: untasked_tasking_plans
    )

    # Abort if the task type is supposed to have steps and any task has 0 steps
    fatal_error(
      code: :empty_tasks, message: 'Tasks could not be published because some tasks were empty'
    ) if new_tasks.any? { |task| !task.stepless? && task.task_steps.empty? }

    # Update existing tasks
    updated_tasks = []
    tasked_tasking_plans.each do |tasking_plan|
      task = tasks_by_role_id[tasking_plan.target_id]

      task.title = task_plan.title
      task.description = task_plan.description
      task.opens_at_ntz = tasking_plan.opens_at_ntz
      task.due_at_ntz = tasking_plan.due_at_ntz
      task.feedback_at_ntz = task_plan.is_feedback_immediate ? nil : tasking_plan.due_at_ntz

      updated_tasks << task if task.changed?
    end

    Tasks::Models::Task.import(
      updated_tasks, validate: false, on_duplicate_key_update: {
        conflict_target: [ :id ],
        columns: [ :title, :description, :opens_at_ntz, :due_at_ntz, :feedback_at_ntz ]
      }
    ) unless updated_tasks.empty?

    unless new_tasks.empty?
      # Taskeds are not saved by recursive: true because they are a belongs_to association
      # So we handle them separately
      new_taskeds = new_tasks.map do |task|
        task.update_cached_attributes

        task.task_steps.map(&:tasked)
      end

      new_taskeds.flatten.group_by(&:class).each do |tasked_class, taskeds|
        tasked_class.import taskeds, validate: false
      end

      new_tasks.each_with_index do |task, task_index|
        task.task_steps.each_with_index do |task_step, step_index|
          task_step.tasked = new_taskeds[task_index][step_index]
          task_step.number = step_index + 1
        end
      end

      new_tasks.each(&:update_cached_attributes)
      Tasks::Models::Task.import new_tasks, recursive: true, validate: false
    end

    changed_tasks = updated_tasks + new_tasks

    unless changed_tasks.empty?
      queue = task_plan.is_preview ? :preview : :dashboard
      Tasks::UpdateTaskCaches.set(queue: queue).perform_later(
        task_ids: changed_tasks.map(&:id), queue: queue.to_s
      )

      OpenStax::Biglearn::Api.create_update_assignments(
        changed_tasks.map { |task| { course: task_plan.course, task: task } }
      )
    end

    outputs.tasks = task_plan.tasks.reset

    # Return without updating timestamps if no tasks were updated and it's not the first publication
    # Should help prevent ActiveRecord::TransactionIsolationConflicts
    return if changed_tasks.empty? && (preview || task_plan.is_published?)

    if preview
      task_plan.touch if task_plan.persisted?
    else
      # Update last_published_at (and first_published_at if this is the first publication)
      task_plan.first_published_at = publish_time if task_plan.first_published_at.nil?
      task_plan.last_published_at = publish_time

      # We are only changing timestamps here, so no reason to validate the record
      task_plan.save(validate: false) if task_plan.persisted?
    end
  end
end
