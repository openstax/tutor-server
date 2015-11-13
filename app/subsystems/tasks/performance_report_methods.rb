module Tasks
  module PerformanceReportMethods
    protected

    # Returns the average for the given tasks
    def average(tasks)
      # Valid tasks must have more than 0 exercises
      # and be started or past due
      valid_tasks = tasks.select do |task|
        (task.task_type == 'homework' || task.task_type == 'concept_coach') &&
        task.exercise_steps_count > 0 &&
        (task.completed_exercise_steps_count > 0 || task.past_due?)
      end

      # Skip if no tasks meet the display requirements
      return if valid_tasks.none?

      valid_tasks.reduce(0) do |sum, task|
        sum + ( task.correct_exercise_steps_count * 100.0 / task.exercise_steps_count )
      end / valid_tasks.size
    end

    def get_student_data(tasks)
      tasks.collect do |task|
        # Skip if the student hasn't worked this particular task_plan/page
        next if task.nil?

        data = {
          late: task.late?,
          status: task.status,
          type: task.task_type,
          id: task.id,
          due_at: task.due_at,
          last_worked_at: task.last_worked_at
        }

        data.merge!(exercise_counts(task)) \
          if task.task_type == 'homework' || task.task_type == 'concept_coach'

        data
      end
    end

    def exercise_counts(task)
      exercise_count  = task.actual_and_placeholder_exercise_count
      correct_count   = task.correct_exercise_steps_count
      recovered_count = task.recovered_exercise_steps_count

      {
        actual_and_placeholder_exercise_count: exercise_count,
        correct_exercise_count: correct_count,
        recovered_exercise_count: recovered_count
      }
    end
  end
end
