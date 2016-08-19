class GetHistory
  TASK_BATCH_SIZE = 10000

  lev_routine express_output: :history

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

    if type == :all || type == :homework
      # Get core_page_ids for all homework task plans at once to minimize DB access
      homework_task_plan_id_to_page_ids_map = {}
      homework_exercise_id_to_task_plan_id_map = {}
      Tasks::Models::TaskPlan.joins(tasks: :taskings)
                             .where(type: 'homework', tasks: {taskings: {entity_role_id: role_ids}})
                             .uniq.pluck(:id, :settings).each do |task_plan_id, settings|
        exercise_ids = (settings['exercise_ids'] || []).compact.map(&:to_i)
        exercise_ids.each do |exercise_id|
          homework_exercise_id_to_task_plan_id_map[exercise_id] ||= []
          homework_exercise_id_to_task_plan_id_map[exercise_id] << task_plan_id
        end
      end
      homework_exercise_ids = homework_exercise_id_to_task_plan_id_map.keys.flatten
      Content::Models::Exercise.where(id: homework_exercise_ids)
                               .pluck(:id, :content_page_id)
                               .each do |exercise_id, content_page_id|
        task_plan_ids = homework_exercise_id_to_task_plan_id_map[exercise_id]

        task_plan_ids.each do |task_plan_id|
          homework_task_plan_id_to_page_ids_map[task_plan_id] ||= []
          homework_task_plan_id_to_page_ids_map[task_plan_id] << content_page_id
        end
      end

      homework_task_plan_id_to_page_ids_map.each do |task_plan_id, page_ids|
        homework_task_plan_id_to_page_ids_map[task_plan_id] = page_ids.uniq
      end
    end

    if type == :all || type == :reading
      # Get core_page_ids for all reading task plans
      reading_task_plan_id_to_page_ids_map = {}
      Tasks::Models::TaskPlan.joins(tasks: :taskings)
                             .where(type: 'reading', tasks: {taskings: {entity_role_id: role_ids}})
                             .uniq.pluck(:id, :settings).each do |task_plan_id, settings|
        page_ids = (settings['page_ids'] || []).compact.map(&:to_i).uniq

        reading_task_plan_id_to_page_ids_map[task_plan_id] = page_ids
      end
    end

    if type == :reading
      # Exclude reading tasks that only have pages without dynamic exercises (intro modules)
      reading_page_ids = reading_task_plan_id_to_page_ids_map.values.flatten
      non_dynamic_reading_page_ids = Content::Models::Page
                                       .joins(:reading_dynamic_pool)
                                       .where(id: reading_page_ids)
                                       .where{reading_dynamic_pool.content_exercise_ids == '[]'}
                                       .pluck(:id)

      excluded_reading_task_plan_ids = reading_task_plan_id_to_page_ids_map
                                         .select do |task_plan_id, page_ids|
        page_ids.all?{ |page_id| non_dynamic_reading_page_ids.include? page_id }
      end.map(&:first)
    end

    query = Tasks::Models::Task.joins{[task_plan.outer, concept_coach_task.outer, taskings]}
                               .where(taskings: {entity_role_id: role_ids})
    query = query.where{tasks_task_plan_id.not_in excluded_reading_task_plan_ids} \
      if type == :reading
    query = query.where(task_type: Tasks::Models::Task.task_types[type]) unless type == :all

    task_count = query.count

    # http://stackoverflow.com/a/15190294
    # This logic works because we don't modify the tasks at all here
    (0..[task_count - TASK_BATCH_SIZE, 0].max).step(TASK_BATCH_SIZE) do |offset|
      tasks = query.order{[opens_at_ntz.desc, due_at_ntz.desc, created_at.desc, id.desc]}
                   .limit(TASK_BATCH_SIZE).offset(offset)
                   .select([Tasks::Models::Task.arel_table[:id],
                            Tasks::Models::Task.arel_table[:task_type],
                            Tasks::Models::Task.arel_table[:time_zone_id],
                            Tasks::Models::Task.arel_table[:created_at],
                            Tasks::Models::Task.arel_table[:opens_at_ntz],
                            Tasks::Models::Task.arel_table[:due_at_ntz],
                            Tasks::Models::Task.arel_table[:tasks_task_plan_id],
                            Tasks::Models::TaskPlan.arel_table[:content_ecosystem_id],
                            Tasks::Models::ConceptCoachTask.arel_table[:content_page_id],
                            Tasks::Models::Tasking.arel_table[:entity_role_id]])
                   .preload(:time_zone)

      tasked_exercises_by_task_id = Tasks::Models::TaskedExercise
        .joins(:task_step, :exercise)
        .where(task_step: { tasks_task_id: tasks.map(&:id) })
        .select([Tasks::Models::TaskStep.arel_table[:tasks_task_id],
                 Content::Models::Exercise.arel_table[:number],
                 Content::Models::Exercise.arel_table[:content_page_id]])
        .group_by(&:tasks_task_id)

      tasks.each do |task|
        role = roles_by_id[task.entity_role_id]
        history = all_history[role]

        history.total_count += 1

        history.task_ids << task.id

        history.task_types << task.task_type.to_sym

        history.ecosystem_ids << task.content_ecosystem_id

        tasked_exercises = tasked_exercises_by_task_id[task.id] || []

        # The core page ids exclude spaced practice/personalized pages
        history.core_page_ids << case task.task_type.to_sym
        when :reading
          reading_task_plan_id_to_page_ids_map[task.tasks_task_plan_id]
        when :homework
          homework_task_plan_id_to_page_ids_map[task.tasks_task_plan_id]
        when :concept_coach
          [task.content_page_id]
        else
          tasked_exercises.map(&:content_page_id).uniq
        end

        # The exercise numbers include core, spaced practice and personalized exercises
        history.exercise_numbers << tasked_exercises.map(&:number)

        # Store some useful dates
        history.created_ats << task.created_at # Date task was assigned
        history.opens_ats << task.opens_at
        history.due_ats << task.due_at
      end
    end

    outputs.history = all_history
  end
end
