module Tasks
  module PerformanceReportMethods
    protected

    def included_in_averages?(task)
      (task.task_type == 'homework' || task.task_type == 'concept_coach') &&
      task.exercise_count > 0
      (task.completed? || task.past_due?)
    end

    def average_scores(tasks)
      applicable_tasks = tasks.select{|task| included_in_averages?(task)}

      return nil if applicable_tasks.none?

      # applicable_tasks.reduce(0) do |sum, task|
      #   sum + task.teacher_chosen_score
      # end / applicable_tasks.size

      average(applicable_tasks, ->(task) {task.teacher_chosen_score})
    end

    def average(array, value_getter=nil)
      num_values = 0

      array.reduce(0) do |sum, item|
        value = value_getter.nil? ? item : value_getter.call(item)
        num_values += 1 if value.present?
        sum + (value || 0)
      end / num_values
    end

    # # Returns the average grade for all exercise steps for the given tasks
    # def total_average(tasks)
    #   # Valid tasks must have more than 0 exercises and be started or past due
    #   valid_tasks = tasks.select do |task|
    #     (task.task_type == 'homework' || task.task_type == 'concept_coach') &&
    #     task.exercise_steps_count > 0 &&
    #     (task.completed_exercise_steps_count > 0 || task.past_due?)
    #   end

    #   # Skip if no tasks meet the display requirements
    #   return if valid_tasks.none?

    #   valid_tasks.reduce(0) do |sum, task|
    #     sum + (task.correct_exercise_steps_count/task.exercise_steps_count.to_f)
    #   end / valid_tasks.size
    # end

    # # Returns the average grade for attempted exercise steps for the given tasks
    # def attempted_average(tasks)
    #   # Valid tasks must have more than 0 exercises and be started or past due
    #   valid_tasks = tasks.select do |task|
    #     (task.task_type == 'homework' || task.task_type == 'concept_coach') &&
    #     task.completed_exercise_steps_count > 0
    #   end

    #   # Skip if no tasks meet the display requirements
    #   return if valid_tasks.none?

    #   valid_tasks.reduce(0) do |sum, task|
    #     # Remove the "min" once https://github.com/openstax/tutor-server/issues/977 is fixed
    #     sum + [task.correct_exercise_steps_count/task.completed_exercise_steps_count.to_f, 1.0].min
    #   end / valid_tasks.size
    # end

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
          is_late_work_accepted: task.is_late_work_accepted
        }

        if task.task_type == 'homework' || task.task_type == 'concept_coach'
          data.merge!(exercise_counts(task))

        end

        data.merge!(is_included_in_averages: included_in_averages?(task))

        data
      end
    end

    def exercise_counts(task)
      exercise_count          = task.actual_and_placeholder_exercise_count
      completed_count         = task.completed_exercise_count
      completed_on_time_count = task.completed_on_time_exercise_count
      correct_count           = task.correct_exercise_count
      correct_on_time_count   = task.correct_on_time_exercise_count
      recovered_count         = task.recovered_exercise_steps_count
      score                   = task.teacher_chosen_score

      {
        actual_and_placeholder_exercise_count: exercise_count,
        completed_exercise_count: completed_count,
        completed_on_time_exercise_count: completed_on_time_count,
        correct_exercise_count: correct_count,
        correct_on_time_count: correct_on_time_count,
        recovered_exercise_count: recovered_count,
        score: score
      }
    end
  end
end
