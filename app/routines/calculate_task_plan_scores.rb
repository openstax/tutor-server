# The scores API (for teachers only) and the grader interface show unpublished points and scores
# Other APIs show published points and scores
class CalculateTaskPlanScores
  lev_routine express_output: :scores

  protected

  def exec(task_plan:)
    current_time = Time.current

    # Preload extensions
    task_plan.extensions.load

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

      # Make arrays of arrays of exercise ids and question ids for exercise steps
      step_exercise_ids = []
      step_question_ids = []
      students_array = tasks.each_with_index.map do |task, student_index|
        task_steps = task_plan.type == 'external' ? task.external_steps :
                                                    task.exercise_and_placeholder_steps
        next if task_steps.empty?

        # Add exercise ids and question_ids to the step arrays above
        exercise_and_placeholder_steps = task_steps.filter { |ts| ts.exercise? || ts.placeholder? }
        exercise_and_placeholder_steps.each_with_index do |task_step, step_index|
          step_exercise_ids[step_index] ||= []
          step_question_ids[step_index] ||= []

          # Placeholder steps don't add anything to the arrays but still take up space
          # by incrementing the step_index so the score columns will line up properly
          next if task_step.placeholder?

          step_exercise_ids[step_index] << task_step.tasked.content_exercise_id
          step_question_ids[step_index] << task_step.tasked.question_id
        end

        role = task.taskings.first.role
        student = role.student
        next if student.nil?

        exercise_steps = exercise_and_placeholder_steps.filter(&:exercise?)
        graded_steps, ungraded_steps = exercise_steps.partition do |task_step|
          task_step.tasked.was_manually_graded?
        end
        grades_need_publishing = (
          !!task.grading_template&.manual_grading_feedback_on_publish? &&
          graded_steps.any? { |task_step| !task_step.tasked.grade_manually_published? }
        ) || (
          !!task.grading_template&.auto_grading_feedback_on_publish? &&
          !task.grades_manually_published? &&
          ungraded_steps.any? do |task_step|
            task_step.completed? && task_step.tasked.can_be_auto_graded?
          end
        )

        is_dropped = student.dropped? || student.period.archived?
        points_per_question_index = task.points_per_question_index_without_lateness
        student_questions = task_steps.each_with_index.map do |task_step, index|
          # This won't work if task_steps contains both exercises and external for the same task
          points = points_per_question_index[index]

          if task_step.external?
            {
              task_step_id: task_step.id,
              is_completed: task_step.completed?,
              needs_grading: false
            }
          elsif task_step.exercise?
            tasked = task_step.tasked

            {
              task_step_id: task_step.id,
              exercise_id: tasked.content_exercise_id,
              question_id: tasked.question_id,
              is_completed: task_step.completed?,
              is_correct: tasked.is_correct?,
              selected_answer_id: tasked.answer_id,
              points: points,
              late_work_point_penalty: tasked.late_work_point_penalty,
              free_response: tasked.free_response,
              grader_points: tasked.grader_points,
              grader_comments: tasked.grader_comments,
              needs_grading: tasked.needs_grading?,
              submitted_late: tasked.submitted_late?
            }
          else
            {
              task_step_id: task_step.id,
              is_completed: task_step.completed?,
              points: points,
              needs_grading: false
            }
          end
        end

        {
          role_id: role.id,
          task_id: task.id,
          first_name: role.profile.first_name,
          last_name: role.profile.last_name,
          is_dropped: is_dropped,
          is_late: task.late?,
          student_identifier: role.student.student_identifier,
          available_points: task.available_points,
          total_points: task.points,
          total_fraction: task.score,
          late_work_point_penalty: task.late_work_point_penalty,
          questions: student_questions,
          grades_need_publishing: grades_need_publishing
        }
      end.compact.sort_by { |student| [ student[:last_name], student[:first_name] ] }

      fractions_array = students_array.reject do |student|
        student[:is_dropped]
      end.map { |student| student[:total_fraction] }.compact
      num_fractions = fractions_array.size
      total_fraction = fractions_array.sum(0.0)/num_fractions unless num_fractions == 0

      longest_task = tasks.max_by(&:actual_and_placeholder_exercise_count)

      available_points_without_dropping_per_question_index =
        longest_task.available_points_without_dropping_per_question_index
      task_steps = task_plan.type == 'external' ? longest_task.external_steps :
                                                  longest_task.exercise_and_placeholder_steps
      zeroed_question_ids_set = Set.new(
        task_plan&.dropped_questions&.filter(&:zeroed?)&.map(&:question_id) || []
      )
      question_headings_array = task_steps.each_with_index.map do |step, index|
        if step.external?
          { title: 'Clicked' }
        else
          title = "Q#{index + 1}"
          question_ids = step_question_ids[index].uniq.sort

          # The index won't work if the same task contains both exercises and external steps
          points_without_dropping = available_points_without_dropping_per_question_index[index]
          points = !zeroed_question_ids_set.empty? && question_ids.all? do |question_id|
            zeroed_question_ids_set.include?(question_id)
          end ? 0.0 : points_without_dropping

          type = step.fixed_group? && step.exercise? ? (
            step.tasked.can_be_auto_graded? ? 'MCQ' : 'WRQ'
          ) : 'Tutor'
          # TODO: Combine logic when exercise_id, question_id are removed
          if type != 'Tutor'
            {
              title: title,
              type: type,
              points_without_dropping: points_without_dropping,
              points: points,
              exercise_ids: step_exercise_ids[index].uniq.sort,
              question_ids: question_ids,
              exercise_id: step.tasked.content_exercise_id,
              question_id: step.tasked.question_id
            }
          else
            {
              title: title,
              type: type,
              points_without_dropping: points_without_dropping,
              points: points,
              exercise_ids: step_exercise_ids[index].uniq.sort,
              question_ids: step_question_ids[index].uniq.sort
            }
          end
        end
      end

      {
        id: tasking_plan.id,
        period_id: tasking_plan.target_id,
        period_name: tasking_plan.target.name,
        question_headings: question_headings_array,
        late_work_fraction_penalty: task_plan.late_work_penalty,
        students: students_array,
        total_fraction: total_fraction,
        gradable_step_count: tasking_plan.gradable_step_count,
        ungraded_step_count: tasking_plan.ungraded_step_count,
        grades_need_publishing: students_array.any? { |student| student[:grades_need_publishing] }
      }
    end.compact
  end
end
