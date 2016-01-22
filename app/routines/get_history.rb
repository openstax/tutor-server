class GetHistory
  lev_routine

  protected

  def exec(role:, type: :all, current_task: nil)
    tasks = Tasks::Models::Task.joins{[task_plan.outer, taskings]}
                               .where(taskings: { entity_role_id: role.id })
                               .order{[due_at.desc, task_plan.created_at.desc, created_at.desc]}
                               .preload([
                                 {task_plan: :ecosystem},
                                 {tasked_exercises: {exercise: {page: :reading_dynamic_pool}}}
                               ])

    tasks = tasks.where(task_type: Tasks::Models::Task.task_types[type]) unless type == :all

    current_task_id = current_task.id unless current_task.nil?

    # Remove the current task and reading tasks without dynamic exercises from the history
    tasks = tasks.to_a.select do |task|
      next false if task.id == current_task_id
      next true if task.task_type != 'reading'

      pages = task.tasked_exercises.map{ |te| te.exercise.page }.uniq
      !pages.all?{ |page| page.reading_dynamic_pool.exercises.empty? }
    end

    # Always put the current_task at the top of the list, if given
    tasks = tasks.unshift(current_task) unless current_task.nil?

    outputs[:tasks] = tasks

    outputs[:ecosystems] = tasks.collect do |task|
      model = task.task_plan.try(:ecosystem)
      next if model.nil?
      strategy = Content::Strategies::Direct::Ecosystem.new(model)
      Content::Ecosystem.new(strategy: strategy)
    end

    tasked_exercises_array = tasks.collect do |task|
      # Handle 0-ago spaced practice
      task.persisted? ? task.tasked_exercises : \
                        task.task_steps.select(&:exercise?).collect(&:tasked)
    end

    outputs[:tasked_exercises] = tasked_exercises_array

    outputs[:exercises] = tasked_exercises_array.collect do |tasked_exercises|
      tasked_exercises.collect do |tasked_exercise|
        model = tasked_exercise.exercise
        strategy = Content::Strategies::Direct::Exercise.new(model)
        Content::Exercise.new(strategy: strategy)
      end
    end
  end
end
