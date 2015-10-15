class GetHistory
  lev_routine

  protected

  def exec(role:, type: :all, current_task: nil)
    tasks = Tasks::Models::Task.joins(:task_plan, :taskings)
                               .where(taskings: { entity_role_id: role.id })
                               .order{[due_at.desc, task_plan.created_at.desc]}
                               .preload([{task_plan: :ecosystem},
                                         {tasked_exercises: {exercise: :page}}])

    tasks = tasks.where(task_type: Tasks::Models::Task.task_types[type]) unless type == :all

    tasks = tasks.where{ id != current_task.id }.to_a.unshift(current_task) \
      unless current_task.nil?

    outputs[:tasks] = tasks.to_a

    outputs[:ecosystems] = tasks.collect do |task|
      model = task.task_plan.ecosystem
      strategy = Content::Strategies::Direct::Ecosystem.new(model)
      Content::Ecosystem.new(strategy: strategy)
    end

    outputs[:exercises] = tasks.collect do |task|
      # Handle 0-ago spaced practice
      tasked_exercises = task.persisted? ? \
                           task.tasked_exercises : \
                           task.task_steps.select(&:exercise?).collect(&:tasked)

      tasked_exercises.collect do |tasked_exercise|
        model = tasked_exercise.exercise
        strategy = Content::Strategies::Direct::Exercise.new(model)
        Content::Exercise.new(strategy: strategy)
      end
    end
  end
end
