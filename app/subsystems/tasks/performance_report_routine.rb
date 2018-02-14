module Tasks::PerformanceReportRoutine

  protected

  def included_in_averages?(task:, current_time_ntz:)
    past_due = task.due_at_ntz.present? && current_time_ntz > task.due_at_ntz

    task.exercise_count > 0 && (
      task.task_type == 'concept_coach' || (
        ['reading', 'homework'].include?(task.task_type) && past_due
      )
    )
  end

  def completion_fraction(tasks:)
    completed_count = tasks.count(&:completed?)

    completed_count.to_f / tasks.count
  end

  def average_score(tasks:, current_time_ntz:)
    applicable_tasks = tasks.compact.select do |task|
      included_in_averages?(task: task, current_time_ntz: current_time_ntz)
    end

    return nil if applicable_tasks.none?

    average(array: applicable_tasks, value_getter: ->(task) { task.score })
  end

  def average_progress(tasks:, current_time_ntz:)
    applicable_tasks = tasks.compact.select do |task|
      included_in_averages?(task: task, current_time_ntz: current_time_ntz)
    end

    return nil if applicable_tasks.none?

    average(array: applicable_tasks, value_getter: ->(task) { task.progress })
  end

  def average(array:, value_getter: nil)
    values = array.map { |item| value_getter.nil? ? item : value_getter.call(item) }.compact
    num_values = values.length
    return if num_values == 0

    values.sum / num_values.to_f
  end

  def get_task_data(tasks:, tz:, current_time_ntz:)
    tasks.map do |task|
      # Skip if the student hasn't worked this particular task_plan/page
      next if task.nil?

      due_at = DateTimeUtilities.apply_tz(task.due_at_ntz, tz)
      late = task.worked_on? && due_at.present? && task.last_worked_at > due_at
      OpenStruct.new(
        {
          task: task,
          late: late,
          status: task.status,
          type: task.task_type,
          id: task.id,
          due_at: due_at,
          last_worked_at: task.last_worked_at,
          is_late_work_accepted: task.accepted_late_at.present?,
          accepted_late_at: task.accepted_late_at,
          is_included_in_averages: included_in_averages?(
            task: task, current_time_ntz: current_time_ntz
          )
        }.tap do |data|
          data.merge!(task_counts(task: task)) \
            if %w(homework reading concept_coach).include?(task.task_type)
        end
      )
    end
  end

  def task_counts(task:)
    {
      step_count:                             task.steps_count,
      completed_step_count:                   task.completed_steps_count,
      completed_on_time_step_count:           task.completed_on_time_steps_count,
      completed_accepted_late_step_count:     task.completed_accepted_late_steps_count,
      actual_and_placeholder_exercise_count:  task.actual_and_placeholder_exercise_count,
      completed_exercise_count:               task.completed_exercise_count,
      completed_on_time_exercise_count:       task.completed_on_time_exercise_count,
      completed_accepted_late_exercise_count: task.completed_accepted_late_exercise_count,
      correct_exercise_count:                 task.correct_exercise_count,
      correct_on_time_exercise_count:         task.correct_on_time_exercise_count,
      correct_accepted_late_exercise_count:   task.correct_accepted_late_exercise_count,
      recovered_exercise_count:               task.recovered_exercise_steps_count,
      score:                                  task.score,
      progress:                               task.progress
    }
  end

end
