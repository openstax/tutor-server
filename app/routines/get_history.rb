class GetHistory
  TASK_BATCH_SIZE = 1000

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

    if type == :all || type == :reading
      # Exclude reading tasks that only have pages without dynamic exercises
      reading_task_plan_id_to_page_ids_map = {}
      Tasks::Models::TaskPlan.joins(tasks: :taskings)
                             .where(type: 'reading', tasks: {taskings: {entity_role_id: role_ids}})
                             .uniq.pluck(:id, :settings).each do |task_plan_id, settings|
        page_ids = (settings['page_ids'] || []).compact.map(&:to_i).uniq

        reading_task_plan_id_to_page_ids_map[task_plan_id] = page_ids
      end

      reading_page_ids = reading_task_plan_id_to_page_ids_map.values.flatten
      reading_pages = Content::Models::Page.where(id: reading_page_ids)
                                           .preload(:reading_dynamic_pool)
                                           .to_a
      non_dynamic_reading_pages = reading_pages.select{ |page| page.reading_dynamic_pool.empty? }
      non_dynamic_reading_page_ids = non_dynamic_reading_pages.map(&:id)

      excluded_reading_task_plan_ids = reading_task_plan_id_to_page_ids_map
                                         .select do |task_plan_id, page_ids|
        page_ids.all?{ |page_id| non_dynamic_reading_page_ids.include? page_id }
      end.map(&:first)
    end

    if type == :all || type == :homework
      # Since getting page_ids for homework task plans requires DB access, get them all at once
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
      homework_exercises = Content::Models::Exercise.where(id: homework_exercise_ids)
                                                    .select([:id, :content_page_id])
      homework_exercises.each do |exercise|
        task_plan_ids = homework_exercise_id_to_task_plan_id_map[exercise.id]
        task_plan_ids.each do |task_plan_id|
          homework_task_plan_id_to_page_ids_map[task_plan_id] ||= []
          homework_task_plan_id_to_page_ids_map[task_plan_id] << exercise.content_page_id
        end
      end

      homework_task_plan_id_to_page_ids_map.each do |task_plan_id, page_ids|
        homework_task_plan_id_to_page_ids_map[task_plan_id] = page_ids.uniq
      end
    end

    query = Tasks::Models::Task.joins{[task_plan.outer, taskings]}
                               .where(taskings: {entity_role_id: role_ids})
    query = query.where{task_plan.id.not_in excluded_reading_task_plan_ids} \
      if type == :all || type == :reading
    query = query.where(task_type: Tasks::Models::Task.task_types[type]) unless type == :all

    task_count = query.count

    # http://stackoverflow.com/a/15190294
    # This logic works because we don't modify the tasks at all here
    (0..[task_count - TASK_BATCH_SIZE, 0].max).step(TASK_BATCH_SIZE) do |offset|
      tasks = query.order{[opens_at_ntz.desc, due_at_ntz.desc, created_at.desc, id.desc]}
                   .limit(TASK_BATCH_SIZE).offset(offset)
                   .select([Tasks::Models::Task.arel_table[Arel.star],
                            Tasks::Models::Tasking.arel_table[:entity_role_id]])
                   .preload([:task_plan, :concept_coach_task,
                             :time_zone, {tasked_exercises: :exercise}])

      tasks.each do |task|
        role = roles_by_id[task.entity_role_id]
        history = all_history[role]

        history.total_count += 1

        history.task_ids << task.id

        history.task_types << task.task_type.to_sym

        history.ecosystem_ids << task.task_plan.try(:content_ecosystem_id)

        # The core page ids exclude spaced practice/personalized pages
        history.core_page_ids << case task.task_type.to_sym
        when :reading
          reading_task_plan_id_to_page_ids_map[task.task_plan.id]
        when :homework
          homework_task_plan_id_to_page_ids_map[task.task_plan.id]
        when :concept_coach
          [task.concept_coach_task.content_page_id]
        else
          task.tasked_exercises.map{ |te| te.exercise.content_page_id }.uniq
        end

        # The exercise numbers include spaced practice/personalized exercises
        history.exercise_numbers << task.tasked_exercises.map{ |te| te.exercise.number }

        # Store some useful dates
        history.created_ats << task.created_at # Date task was assigned
        history.opens_ats << task.opens_at
        history.due_ats << task.due_at
      end
    end

    outputs.history = all_history
  end
end
