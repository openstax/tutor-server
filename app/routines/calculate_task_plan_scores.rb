class CalculateTaskPlanScores
  lev_routine express_output: :scores

  uses_routine GetMostCommonTask

  protected

  def exec(task_plan:)
    current_time = Time.current

    # Preload each task's student and period
    tasks = task_plan.tasks.preload(:course, taskings: { role: :student })

    ActiveRecord::Associations::Preloader.new.preload tasks, task_steps: :tasked

    # Group tasking_plans and tasks by period
    period_tasking_plans = task_plan.tasking_plans.filter do |tasking_plan|
      tasking_plan.target_type == 'CourseMembership::Models::Period'
    end

    ActiveRecord::Associations::Preloader.new.preload period_tasking_plans, :target

    period_tasking_plans = period_tasking_plans.reject do |tasking_plan|
      tasking_plan.target.archived?
    end.sort_by { |tasking_plan| tasking_plan.target.name }

    tasks_by_period_id = tasks.filter do |task|
      task.taskings.all? { |tasking| tasking.role.student? }
    end.group_by do |task|
      period_ids = task.taskings.map do |tasking|
        tasking.role.student.course_membership_period_id
      end.uniq
      raise(
        NotImplementedError,
        'Each task in CalculateTaskPlanScores must belong to exactly 1 period'
      ) if period_ids.size != 1

      period_ids.first
    end

    outputs.scores = period_tasking_plans.map do |tasking_plan|
      tasks = tasks_by_period_id[tasking_plan.target_id]
      next if tasks.blank?

      most_common_task = run(:get_most_common_task, tasks: tasks).outputs.task

      available_points_without_dropping_per_question_index =
        most_common_task.available_points_without_dropping_per_question_index
      available_points_per_question_index = most_common_task.available_points_per_question_index
      exercise_steps = most_common_task.exercise_and_placeholder_steps
      question_headings_array = exercise_steps.each_with_index.map do |step, index|
        {
         title: "Q#{index + 1}",
         points_without_dropping: available_points_without_dropping_per_question_index[index],
         points: available_points_per_question_index[index],
         type: step.is_core ? (step.tasked.can_be_auto_graded? ? 'MCQ' : 'WRQ') : 'Tutor',
         question_id: step.exercise? && step.is_core? ? step.tasked.question_id : nil,
         exercise_id: step.exercise? && step.is_core? ? step.tasked.content_exercise_id : nil,
        }
      end
      if task_plan.type == 'homework'
        expected_num_questions = task_plan.settings.fetch('exercises').map do |exercise|
          exercise['points'].size
        end.sum + task_plan.settings.fetch('exercises_count_dynamic', 3)
        actual_num_questions = most_common_task.actual_and_placeholder_exercise_count
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
            tasked = task_step.tasked

            {
              task_step_id: task_step.id,
              exercise_id: tasked.content_exercise_id,
              question_id: tasked.question_id,
              is_completed: task_step.completed?,
              selected_answer_id: tasked.answer_id,
              points: points,
              free_response: tasked.free_response,
              grader_points: tasked.grader_points,
              grader_comments: tasked.grader_comments,
              needs_grading: tasked.needs_grading?
            }
          else
            {
              task_step_id: task_step.id,
              is_completed: false,
              points: points,
              needs_grading: false
            }
          end
        end

        completed_questions = student_questions.filter { |question| question[:is_completed] }
        questions_need_grading = completed_questions.any? { |question| question[:needs_grading] }
        grades_need_publishing = task.grading_template&.manual_grading_feedback_on_publish? &&
                                 exercise_steps.filter(&:exercise?).any? do |task_step|
          task_step.tasked.grade_needs_publishing?
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
          questions: student_questions,
          questions_need_grading: questions_need_grading,
          grades_need_publishing: grades_need_publishing
        }
      end.compact.sort_by { |student| [ student[:last_name], student[:first_name] ] }

      {
        id: tasking_plan.id,
        period_id: tasking_plan.target_id,
        period_name: tasking_plan.target.name,
        question_headings: question_headings_array,
        late_work_fraction_penalty: task_plan.grading_template&.late_work_penalty || 0,
        num_questions_dropped: num_questions_dropped,
        points_dropped: points_dropped,
        students: students_array,
        questions_need_grading: students_array.any? { |student| student[:questions_need_grading] },
        grades_need_publishing: students_array.any? { |student| student[:grades_need_publishing] }
      }
    end.compact
  end
end
