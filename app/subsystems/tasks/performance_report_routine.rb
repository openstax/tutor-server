module Tasks::PerformanceReportRoutine

  protected

  def included_in_progress_averages?(task:, current_time_ntz:)
    return false if task.steps_count == 0
    return true if task.task_type == 'concept_coach'

    task.due_at_ntz.present? && task.due_at_ntz <= current_time_ntz
  end

  def included_in_score_averages?(task:, current_time_ntz:, is_teacher:)
    return false if task.actual_and_placeholder_exercise_count == 0

    included_in_progress_averages?(task: task, current_time_ntz: current_time_ntz) && (
      is_teacher || task.feedback_at_ntz.nil? || task.feedback_at_ntz <= current_time_ntz
    )
  end

  def completion_fraction(tasks:)
    completed_count = tasks.count { |tt| tt.completed?(use_cache: true) }

    completed_count.to_f / tasks.count
  end

  def average_score(tasks:, current_time_ntz:, is_teacher:)
    applicable_tasks = tasks.compact.select do |task|
      included_in_score_averages?(
        task: task, current_time_ntz: current_time_ntz, is_teacher: is_teacher
      )
    end

    return nil if applicable_tasks.empty?

    average(array: applicable_tasks, value_getter: ->(task) { task.score })
  end

  def average_progress(tasks:, current_time_ntz:)
    applicable_tasks = tasks.compact.select do |task|
      included_in_progress_averages?(task: task, current_time_ntz: current_time_ntz)
    end

    return nil if applicable_tasks.empty?

    average(array: applicable_tasks, value_getter: ->(task) { task.progress })
  end

  def average(array:, value_getter: nil)
    values = array.map { |item| value_getter.nil? ? item : value_getter.call(item) }.compact
    num_values = values.length
    return if num_values == 0

    values.sum / num_values.to_f
  end

  def get_task_data(tasks:, tz:, current_time_ntz:, is_teacher:)
    tasks.map do |tt|
      # Skip if the student hasn't worked this particular task_plan/page
      next if tt.nil?

      due_at = DateTimeUtilities.apply_tz(tt.due_at_ntz, tz)
      late = tt.worked_on? && due_at.present? && tt.last_worked_at > due_at
      type = tt.task_type
      show_score = is_teacher || tt.feedback_at_ntz.nil? || tt.feedback_at_ntz <= current_time_ntz
      OpenStruct.new(
        {
          task: tt,
          late: late,
          status: tt.status(use_cache: true),
          type: type,
          id: tt.id,
          due_at: due_at,
          last_worked_at: tt.last_worked_at.try!(:in_time_zone, tz),
          is_late_work_accepted: tt.accepted_late_at.present?,
          accepted_late_at: tt.accepted_late_at.try!(:in_time_zone, tz),
          is_included_in_averages: included_in_progress_averages?(
            task: tt, current_time_ntz: current_time_ntz
          )
        }.tap do |data|
          correct_exercise_count = show_score ? tt.correct_exercise_count : nil
          correct_on_time_exercise_count = show_score ? tt.correct_on_time_exercise_count : nil
          correct_accepted_late_exercise_count = show_score ?
            tt.correct_accepted_late_exercise_count : nil
          score = show_score ? tt.score : nil

          data.merge!(
            step_count:                             tt.steps_count,
            completed_step_count:                   tt.completed_steps_count,
            completed_on_time_step_count:           tt.completed_on_time_steps_count,
            completed_accepted_late_step_count:     tt.completed_accepted_late_steps_count,
            actual_and_placeholder_exercise_count:  tt.actual_and_placeholder_exercise_count,
            completed_exercise_count:               tt.completed_exercise_count,
            completed_on_time_exercise_count:       tt.completed_on_time_exercise_count,
            completed_accepted_late_exercise_count: tt.completed_accepted_late_exercise_count,
            correct_exercise_count:                 correct_exercise_count,
            correct_on_time_exercise_count:         correct_on_time_exercise_count,
            correct_accepted_late_exercise_count:   correct_accepted_late_exercise_count,
            recovered_exercise_count:               tt.recovered_exercise_steps_count,
            score:                                  score,
            progress:                               tt.progress
          )
        end
      )
    end
  end

end
