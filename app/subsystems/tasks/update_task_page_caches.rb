class Tasks::UpdateTaskPageCaches
  lev_routine

  protected

  def exec(tasks:)
    task_ids = [tasks].flatten.map(&:id)

    student_ids_by_task_id = Hash.new { |hash, key| hash[key] = [] }
    CourseMembership::Models::Student.joins(role: :taskings)
                                     .where(role: { taskings: { tasks_task_id: task_ids } })
                                     .pluck(:id, :tasks_task_id)
                                     .each do |id, task_id|
      student_ids_by_task_id[task_id] << id
    end

    exercise_counts_by_task_id = Tasks::Models::TaskedExercise
      .select([
        '"tasks_task_steps"."tasks_task_id"',
        '"tasks_task_steps"."content_page_id"',
        'COUNT(*) AS "assigned"',
        'COUNT("tasks_task_steps"."first_completed_at") AS "completed"',
        'COUNT(*) FILTER (WHERE "tasks_tasked_exercises"."answer_id" =' +
          '"tasks_tasked_exercises"."correct_answer_id") AS "correct"'
      ])
      .joins(:task_step)
      .where(task_step: { tasks_task_id: task_ids })
      .group(task_step: [ :tasks_task_id, :content_page_id ])
      .group_by(&:tasks_task_id)

    # Cache results per student per task per CNX section for Quick Look and Performance Forecast
    task_page_caches = task_ids.flat_map do |task_id|
      exercise_counts = exercise_counts_by_task_id[task_id] || []
      student_ids = student_ids_by_task_id[task_id]

      exercise_counts.flat_map do |exercise_count|
        student_ids.map do |student_id|
          Tasks::Models::TaskPageCache.new(
            tasks_task_id: task_id,
            course_membership_student_id: student_id,
            content_page_id: exercise_count.content_page_id,
            num_assigned_exercises: exercise_count.assigned,
            num_completed_exercises: exercise_count.completed,
            num_correct_exercises: exercise_count.correct
          )
        end
      end
    end

    Tasks::Models::TaskPageCache.import task_page_caches, validate: false,
                                                          on_duplicate_key_update: {
      conflict_target: [ :course_membership_student_id, :content_page_id, :tasks_task_id ],
      columns: [ :num_assigned_exercises, :num_completed_exercises, :num_correct_exercises ]
    }
  end
end
