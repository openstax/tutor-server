class GetHistory
  MAX_ROLES_PER_QUERY = 10

  lev_routine express_output: :history

  protected

  def exec(roles:, type: :all)
    all_history = Hashie::Mash.new

    [roles].flatten.compact.each_slice(MAX_ROLES_PER_QUERY) do |roles_slice|
      roles_by_id = roles_slice.index_by(&:id)
      role_ids = roles_by_id.keys

      all_tasks = Tasks::Models::Task
        .joins{[task_plan.outer, taskings]}
        .where(taskings: { entity_role_id: role_ids })
        .preload([:task_plan, :concept_coach_task, {tasked_exercises: :exercise}])
        .select([Tasks::Models::Task.arel_table[Arel.star],
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

      # Add an empty array for roles with no tasks
      taskless_role_ids = role_ids.reject{ |role_id| grouped_tasks.has_key? role_id }
      taskless_role_ids.each{ |role_id| grouped_tasks[role_id] = [] }

      # Since getting page_ids for homework tasks requires DB access, get them all at once
      exercise_id_to_page_id_map = {}
      homework_tasks = all_tasks.select(&:homework?)
      all_hw_exercise_ids = homework_tasks.flat_map{ |task| task.task_plan.settings['exercise_ids'] }
      all_hw_exercises = Content::Models::Exercise.where(id: all_hw_exercise_ids)
                                                  .select([:id, :content_page_id])
      all_hw_exercises.each do |exercise|
        exercise_id_to_page_id_map[exercise.id] = exercise.content_page_id
      end

      grouped_tasks.each do |entity_role_id, tasks|
        history = Hashie::Mash.new

        role = roles_by_id[entity_role_id]

        sorted_tasks = tasks.sort_by do |task|
          due_date = task.due_at_ntz.to_f
          open_date = task.opens_at_ntz.to_f
          tie_breaker = (task.task_plan || task).created_at.to_f

          [due_date, open_date, tie_breaker]
        end.reverse!

        history.total_count = sorted_tasks.size

        history.ecosystem_ids = sorted_tasks.map{ |task| task.task_plan.try(:content_ecosystem_id) }

        # The core page ids exclude spaced practice/personalized pages
        history.core_page_ids = sorted_tasks.map do |task|
          case task.task_type.to_sym
          when :reading
            task.task_plan.settings['page_ids'].compact.map(&:to_i)
          when :homework
            exercise_ids = task.task_plan.settings['exercise_ids'].compact.map(&:to_i)
            exercise_ids.map{ |exercise_id| exercise_id_to_page_id_map[exercise_id] }.compact.uniq
          when :concept_coach
            [task.concept_coach_task.content_page_id]
          else
            task.tasked_exercises.map{ |te| te.exercise.content_page_id }.uniq
          end
        end

        # The exercise numbers include spaced practice/personalized exercises
        history.exercise_numbers = sorted_tasks.map do |task|
          task.tasked_exercises.map{ |te| te.exercise.number }
        end

        all_history[role] = history
      end
    end

    outputs.history = all_history
  end
end
