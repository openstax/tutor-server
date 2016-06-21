class GetHistory
  lev_routine express_output: :history

  protected

  def exec(roles:, type: :all)
    roles = [roles].flatten.compact
    roles_by_id = roles.index_by(&:id)
    role_ids = roles_by_id.keys

    all_tasks = Tasks::Models::Task
      .joins{[task_plan.outer, taskings]}
      .where(taskings: { entity_role_id: role_ids })
      .preload([
        {task_plan: :ecosystem},
        {tasked_exercises: [:task_step, {exercise: :page}]}
      ]).select([Tasks::Models::Task.arel_table[Arel.star],
                 Tasks::Models::Tasking.arel_table[:entity_role_id]])

    all_tasks = all_tasks.where(task_type: Tasks::Models::Task.task_types[type]) unless type == :all

    reading_tasks, other_tasks = all_tasks.partition(&:reading?)

    # Find reading pages without dynamic exercises
    grouped_reading_tasks = reading_tasks.group_by(&:task_plan).map do |task_plan, tasks|
      [(task_plan.settings['page_ids'] || []).compact, tasks]
    end
    reading_page_ids = grouped_reading_tasks.map(&:first).flatten.uniq
    reading_pages = Content::Models::Page.where(id: reading_page_ids).preload(:reading_dynamic_pool)
    non_dynamic_reading_pages = reading_pages.to_a.select{ |page| page.reading_dynamic_pool.empty? }
    non_dynamic_reading_page_ids_set = non_dynamic_reading_pages.map(&:id)

    # Remove reading tasks without dynamic exercises from the history
    filtered_grouped_reading_tasks = grouped_reading_tasks.reject do |page_ids, tasks|
      reading_page_ids = page_ids.map(&:to_i)
      reading_page_ids.all?{ |page_id| non_dynamic_reading_page_ids_set.include? page_id }
    end
    filtered_reading_tasks = filtered_grouped_reading_tasks.flat_map(&:second)

    filtered_tasks = filtered_reading_tasks + other_tasks
    grouped_tasks = filtered_tasks.group_by(&:entity_role_id)

    taskless_role_ids = role_ids.reject{ |role_id| grouped_tasks.has_key? role_id }
    taskless_role_ids.each{ |role_id| grouped_tasks[role_id] = [] }

    all_history = Hashie::Mash.new

    grouped_tasks.each do |entity_role_id, tasks|
      history = Hashie::Mash.new

      role = roles_by_id[entity_role_id]

      sorted_tasks = tasks.sort_by do |task|
        due_date = task.due_at_ntz.to_f
        open_date = task.opens_at_ntz.to_f
        tie_breaker = (task.task_plan || task).created_at.to_f

        [due_date, open_date, tie_breaker]
      end.reverse!

      history.tasks = sorted_tasks

      history.ecosystems = sorted_tasks.map do |task|
        model = task.task_plan.try(:ecosystem)
        next if model.nil?

        Content::Ecosystem.new(strategy: model.wrap)
      end

      tasked_exercises_array = sorted_tasks.map(&:tasked_exercises)

      history.tasked_exercises = tasked_exercises_array

      history.exercises = tasked_exercises_array.map do |tasked_exercises|
        tasked_exercises.map do |tasked_exercise|
          Content::Exercise.new(strategy: tasked_exercise.exercise.wrap)
        end
      end

      all_history[role] = history
    end

    outputs.history = all_history
  end
end
