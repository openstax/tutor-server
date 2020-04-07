class CalculateTaskPlanScores
  lev_routine express_output: :scores

  protected

  def exec(task_plan:)
    current_time = Time.current

    # Preload each task's student and period
    tasks = task_plan.tasks.preload(
      :time_zone, taskings: [ :period, role: :student ]
    ).reject do |task|
      task.taskings.all? do |tasking|
        period = tasking.period
        student = tasking.role.student

        period.nil? || period.archived? || student.nil?
      end
    end

    ActiveRecord::Associations::Preloader.new.preload tasks, task_steps: :tasked

    # Group tasks by period
    tasks_by_period = tasks.group_by do |task|
      periods = task.taskings.map(&:period).uniq
      raise(
        NotImplementedError,
        'Each task in CalculateTaskPlanScores must belong to exactly 1 period'
      ) if periods.size != 1

      periods.first
    end

    outputs.scores = tasks_by_period.sort_by { |period, _| period.name }.map do |period, tasks|
      no_placeholder_tasks = tasks.select { |task| task.placeholder_steps_count == 0 }
      representative_tasks = no_placeholder_tasks.empty? ? tasks : no_placeholder_tasks
      most_common_tasks = representative_tasks.group_by(
        &:actual_and_placeholder_exercise_count
      ).max_by { |_, tasks| tasks.size }.second
      most_common_task = most_common_tasks.first

      available_points_per_question_index = most_common_task.available_points_per_question_index
      exercise_steps = most_common_task.exercise_and_placeholder_steps
      question_headings_array = exercise_steps.each_with_index.map do |step, index|
        {
         title: "Q#{index + 1}",
         points: available_points_per_question_index[index],
         type: step.is_core ? 'MCQ' : 'Tutor', # TODO: actually check if exercise is MCQ
         question_id: step.exercise? && step.is_core? ? step.tasked.question_id : nil,
         exercise_id: step.exercise? && step.is_core? ? step.tasked.content_exercise_id : nil,
        }
      end
      if task_plan.type == 'homework'
        expected_num_questions = task_plan.settings.fetch('exercises').map do |exercise|
          exercise['points'].size
        end.sum + task_plan.settings.fetch('exercises_count_dynamic', 3)
        actual_num_questions = most_common_tasks.first.actual_and_placeholder_exercise_count
        num_questions_dropped = expected_num_questions - actual_num_questions
      else
        num_questions_dropped = 0
      end
      points_dropped = num_questions_dropped.to_f

      students_array = tasks.each_with_index.map do |task, student_index|
        role = task.taskings.first.role
        student = role.student
        next if student.nil?

        role = task.taskings.first.role

        exercise_steps = task.exercise_and_placeholder_steps
        next if exercise_steps.empty?

        is_dropped = student.dropped? || student.period.archived?

        points_per_question_index = task.points_per_question_index_without_lateness(
          incomplete_value: task.past_due?(current_time: current_time) ? 0.0 : nil
        )
        student_questions = exercise_steps.each_with_index.map do |task_step, index|
          points = points_per_question_index[index]

          if task_step.exercise?
            {
              id: task_step.tasked.question_id,
              exercise_id: task_step.tasked.content_exercise_id,
              is_completed: task_step.completed?,
              selected_answer_id: task_step.tasked.answer_id,
              points: points,
              free_response: task_step.tasked.free_response
            }
          else
            { is_completed: false, points: points }
          end
        end

        {
          role_id: role.id,
          first_name: role.profile.first_name,
          last_name: role.profile.last_name,
          is_dropped: is_dropped,
          is_late: task.late?,
          student_identifier: role.student.student_identifier,
          available_points: task.available_points,
          total_points: task.points,
          total_fraction: task.score,
          late_work_point_penalty: task.late_work_point_penalty,
          late_work_fraction_penalty: task.late_work_penalty,
          questions: student_questions
        }
      end.compact.sort_by { |student| [ student[:last_name], student[:first_name] ] }

      {
        id: period.id,
        name: period.name,
        question_headings: question_headings_array,
        late_work_fraction_penalty: task_plan.grading_template&.late_work_penalty || 0,
        num_questions_dropped: num_questions_dropped,
        points_dropped: points_dropped,
        students: students_array
      }
    end
  end
end
