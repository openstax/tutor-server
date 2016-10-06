class GetHistory
  TASK_BATCH_SIZE = 10000
  TASKED_EXERCISE_BATCH_SIZE = 50000

  lev_routine express_output: :history

  uses_routine GetTaskCorePageIds, as: :get_task_core_page_ids

  protected

  def exec(roles:, type: :all)
    roles = [roles].flatten.compact

    all_history = Hashie::Mash.new
    roles.each do |role|
      all_history[role] = Hashie::Mash.new(
        total_count: 0, task_ids: [], task_types: [], ecosystem_ids: [], core_page_ids: [],
        exercise_numbers: [], created_ats: [], opens_ats: [], due_ats: []
      )
    end

    roles_by_id = roles.index_by(&:id)
    role_ids = roles_by_id.keys

    query = Tasks::Models::Task.joins{[task_plan.outer, time_zone.outer, taskings]}
                               .where(taskings: {entity_role_id: role_ids})

    query = query.where(task_type: Tasks::Models::Task.task_types[type]) unless type == :all

    all_tasks = query.dup.select([:id, :task_type, :tasks_task_plan_id]).to_a

    task_id_to_core_page_ids_map = run(:get_task_core_page_ids, tasks: all_tasks)
                                     .outputs.task_id_to_core_page_ids_map

    if type == :reading
      # Exclude reading tasks that only have pages without dynamic exercises (intro modules)
      reading_page_ids = task_id_to_core_page_ids_map.values.flatten
      non_dynamic_reading_page_ids = Content::Models::Page
                                       .joins(:reading_dynamic_pool)
                                       .where(id: reading_page_ids)
                                       .where{reading_dynamic_pool.content_exercise_ids == '[]'}
                                       .pluck(:id)

      excluded_reading_task_ids = task_id_to_core_page_ids_map.select do |task_id, core_page_ids|
        core_page_ids.all?{ |page_id| non_dynamic_reading_page_ids.include? page_id }
      end.map(&:first)

      query = query.where{id.not_in excluded_reading_task_ids}
    end

    # Preloading does not work with cursors, so we load other records separately
    tasked_exercises_by_task_id = Tasks::Models::TaskedExercise
      .joins(:task_step, :exercise)
      .where(task_step: { tasks_task_id: all_tasks.map(&:id) })
      .select([Tasks::Models::TaskStep.arel_table[:tasks_task_id],
               Content::Models::Exercise.arel_table[:number],
               Content::Models::Exercise.arel_table[:content_page_id]])
      .each_instance(block_size: TASKED_EXERCISE_BATCH_SIZE)
      .group_by(&:tasks_task_id)

    tasks = query.uniq
                 .order{[due_at_ntz.desc, opens_at_ntz.desc, created_at.desc, id.desc]}
                 .select([Tasks::Models::Task.arel_table[:id],
                          Tasks::Models::Task.arel_table[:task_type],
                          Tasks::Models::Task.arel_table[:time_zone_id],
                          Tasks::Models::Task.arel_table[:created_at],
                          Tasks::Models::Task.arel_table[:opens_at_ntz],
                          Tasks::Models::Task.arel_table[:due_at_ntz],
                          Tasks::Models::Task.arel_table[:tasks_task_plan_id],
                          Tasks::Models::TaskPlan.arel_table[:content_ecosystem_id],
                          Tasks::Models::Tasking.arel_table[:entity_role_id],
                          TimeZone.arel_table[:name].as('time_zone_name')])
                 .each_instance(block_size: TASK_BATCH_SIZE) do |task|
      role = roles_by_id[task.entity_role_id]

      history = all_history[role]

      history.total_count += 1

      history.task_ids << task.id
      history.task_types << task.task_type.to_sym

      history.ecosystem_ids << task.content_ecosystem_id

      tasked_exercises = tasked_exercises_by_task_id[task.id] || []

      # The core page ids exclude spaced practice/personalized pages
      history.core_page_ids << task_id_to_core_page_ids_map[task.id]

      # The exercise numbers include core, spaced practice and personalized exercises
      history.exercise_numbers << tasked_exercises.map(&:number)

      # Store some useful dates
      # Only the time zone name was preloaded, so we have to manually apply it
      tz = task.time_zone_name.nil? ? Time.zone : ActiveSupport::TimeZone[task.time_zone_name]

      history.created_ats << task.created_at # Task publication date
      history.opens_ats << DateTimeUtilities.apply_tz(task.opens_at_ntz, tz)
      history.due_ats << DateTimeUtilities.apply_tz(task.due_at_ntz, tz)
    end

    outputs.history = all_history
  end
end
