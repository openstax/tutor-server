class GetHistory
  lev_routine

  protected

  def exec(role:, type: :all, current_task: nil)
    tasks = Tasks::Models::Task.joins{[task_plan.outer, taskings]}
                               .where(taskings: { entity_role_id: role.id })
                               .order{[due_at_ntz.desc, task_plan.created_at.desc, created_at.desc]}
                               .preload([
                                 {task_plan: :ecosystem},
                                 {tasked_exercises: [:task_step, {exercise: :page}]}
                               ])

    tasks = tasks.where(task_type: Tasks::Models::Task.task_types[type]) unless type == :all

    current_task_id = current_task.id unless current_task.nil?

    # Find reading pages without dynamic exercises
    reading_page_ids = tasks.select(&:reading?)
                            .flat_map{ |task| task.task_plan.settings['page_ids'] }.compact.uniq
    reading_pages = Content::Models::Page.where(id: reading_page_ids).preload(:reading_dynamic_pool)
    non_dynamic_reading_pages = reading_pages.to_a.select{ |page| page.reading_dynamic_pool.empty? }
    non_dynamic_reading_page_ids_set = Set.new non_dynamic_reading_pages.map(&:id)

    # Remove the current task and reading tasks without dynamic exercises from the history
    tasks = tasks.to_a.reject do |task|
      next true if task.id == current_task_id
      next false unless task.task_type == 'reading'

      reading_page_ids_set = Set.new task.task_plan.settings['page_ids'].map(&:to_i)
      reading_page_ids_set.subset? non_dynamic_reading_page_ids_set
    end

    # Always put the current_task at the top of the list, if given
    tasks = tasks.unshift(current_task) unless current_task.nil?

    outputs[:tasks] = tasks

    outputs[:ecosystems] = tasks.map do |task|
      model = task.task_plan.try(:ecosystem)
      next if model.nil?

      strategy = Content::Strategies::Direct::Ecosystem.new(model)
      Content::Ecosystem.new(strategy: strategy)
    end

    tasked_exercises_array = tasks.map do |task|
      # Handle 0-ago spaced practice
      task.persisted? ? task.tasked_exercises : \
                        task.task_steps.select(&:exercise?).map(&:tasked)
    end

    outputs[:tasked_exercises] = tasked_exercises_array

    outputs[:exercises] = tasked_exercises_array.map do |tasked_exercises|
      tasked_exercises.map do |tasked_exercise|
        model = tasked_exercise.exercise
        strategy = Content::Strategies::Direct::Exercise.new(model)
        Content::Exercise.new(strategy: strategy)
      end
    end
  end
end
