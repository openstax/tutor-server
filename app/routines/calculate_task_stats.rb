class CalculateTaskStats
  lev_routine express_output: :stats

  protected

  def exec(tasks:)
    current_time = Time.current

    # Preload each task's student and period
    tasks = [ tasks ].flatten
    ActiveRecord::Associations::Preloader.new.preload(
      tasks, taskings: [ role: { student: :period } ]
    )
    tasks = tasks.reject do |task|
      task.taskings.all? do |tasking|
        student = tasking.role.student
        period = student&.period

        period.nil? || period.archived? || student.nil? || student.dropped?
      end
    end

    # Group tasks by period
    tasks_by_period = tasks.group_by do |task|
      periods = task.taskings.map(&:role).map(&:student).map(&:period).uniq

      raise(
        NotImplementedError, 'Each task in CalculateTaskStats must belong to exactly 1 period'
      ) if periods.size != 1

      periods.first
    end

    outputs.stats = tasks_by_period.map do |period, tasks|
      num_tasks = tasks.size
      started_tasks = tasks.select(&:started?)
      num_in_progress_tasks = tasks.count(&:in_progress?)
      num_completed_tasks = tasks.count(&:completed?)

      {
        period_id: period.id,
        name: period.name,
        total_count: num_tasks,
        complete_count: num_completed_tasks,
        partially_complete_count: num_in_progress_tasks
      }
    end.compact
  end
end
