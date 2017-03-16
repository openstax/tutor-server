# Note: Not a real ActiveSupport::Concern but no reason it couldn't be
module Tasks::PerformanceReportRoutine

  protected

  def completion_fraction(tasks)
    completed_count = tasks.count(&:completed?)

    completed_count.to_f / tasks.count
  end

  def included_in_averages?(task)
    task.exercise_count > 0 &&
    (
      ( task.task_type == 'concept_coach' ) ||
      ( task.task_type == 'homework' && task.past_due? )
    )
  end

  def average_scores(tasks)
    applicable_tasks = tasks.compact.select{|task| included_in_averages?(task)}

    return nil if applicable_tasks.none?

    average(applicable_tasks, ->(task) {task.score})
  end

  def average(array, value_getter=nil)
    num_values = 0

    value_sum = array.reduce(0) do |sum, item|
      value = value_getter.nil? ? item : value_getter.call(item)
      num_values += 1 if value.present?
      sum + (value || 0)
    end

    num_values == 0 ? nil : value_sum / num_values
  end

  def get_student_data(tasks)
    tasks.map do |task|
      # Skip if the student hasn't worked this particular task_plan/page
      next if task.nil?

      data = {
        task: task,
        late: task.late?,
        status: task.status,
        type: task.task_type,
        id: task.id,
        due_at: task.due_at,
        last_worked_at: task.last_worked_at,
        is_late_work_accepted: task.accepted_late_at.present?,
        accepted_late_at: task.accepted_late_at
      }

      if %w(homework concept_coach reading).include?(task.task_type)
        data.merge!(task_counts(task))
      end

      data.merge!(is_included_in_averages: included_in_averages?(task))

      data
    end
  end

  def task_counts(task)
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
      score:                                  task.score
    }
  end

end
