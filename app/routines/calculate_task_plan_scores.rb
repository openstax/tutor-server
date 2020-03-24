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

    ActiveRecord::Associations::Preloader.new.preload tasks, :task_steps

    # We load these separately because we don't need the huge exercise content field
    tasked_exercise_ids = tasks.flat_map(&:task_steps).select(&:exercise?).map(&:tasked_id)
    tasked_exercise_by_id = Tasks::Models::TaskedExercise.select(
      :id, :correct_answer_id, :answer_id, :free_response, :content_exercise_id,
    ).where(id: tasked_exercise_ids).index_by(&:id)

    # Group tasks by period
    tasks_by_period = tasks.group_by do |task|
      periods = task.taskings.map(&:period).uniq
      raise(
        NotImplementedError,
        'Each task in CalculateTaskPlanScores must belong to exactly 1 period'
      ) if periods.size != 1

      periods.first
    end

    available_points_per_question_index = Hash.new 1.0
    if task_plan.type == 'homework'
      question_index = 0
      task_plan.settings.fetch('exercises', []).each do |exercise|
        exercise['points'].each do |points|
          available_points_per_question_index[question_index] = points
          question_index += 1
        end
      end
    end

    outputs.scores = tasks_by_period.sort_by { |period, _| period.name }.map do |period, tasks|
      no_placeholder_tasks = tasks.select { |task| task.placeholder_steps_count == 0 }
      representative_tasks = no_placeholder_tasks.empty? ? tasks : no_placeholder_tasks
      most_common_tasks = representative_tasks.group_by(
        &:actual_and_placeholder_exercise_count
      ).max_by { |_, tasks| tasks.size }.second

      exercise_steps = most_common_tasks.first.task_steps.filter do |step|
        step.exercise? || step.placeholder?
      end
      question_headings_array = exercise_steps.each_with_index.map do |step, index|
        {
         title: "Q#{index + 1}",
         type: step.is_core ? 'MCQ' : 'Tutor', # TODO: actually check if exercise is MCQ
         points: available_points_per_question_index[index]
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

      all_question_points = []
      students_array = tasks.each_with_index.map do |task, student_index|
        role = task.taskings.first.role
        student = role.student
        next if student.nil?

        role = task.taskings.first.role

        exercise_steps = task.task_steps.filter { |step| step.exercise? || step.placeholder? }
        next if exercise_steps.empty?

        is_dropped = student.dropped? || student.period.archived?

        available_points = exercise_steps.size.times.map do |index|
          available_points_per_question_index[index]
        end.sum

        student_questions = exercise_steps.each_with_index.map do |task_step, index|
          if task_step.placeholder?
            {
             is_completed: false,
             points: task.late? ? 0.0 : nil
            }
          else
            tasked = tasked_exercise_by_id[task_step.tasked_id]
            {
              id: task_step.tasked.question_id,
              exercise_id: tasked.content_exercise_id,
              is_completed: task_step.completed?,
              selected_answer_id: task_step.tasked.answer_id,
              points: tasked.is_correct? ? available_points_per_question_index[index] : 0.0,
              free_response: tasked.free_response,
            }
          end
        end

        total_points_without_lateness = student_questions.map{|sq| sq[:points] }.compact.sum

        late_work_fraction_penalty = task.late_work_penalty
        late_work_point_penalty = late_work_fraction_penalty * total_points_without_lateness

        total_points = total_points_without_lateness - late_work_point_penalty

        worked_points = 0.0
        student_questions.each_with_index do |sq, index|
          all_question_points[index] ||= []
          next if sq[:points].nil?

          all_question_points[index] << sq[:points]
          worked_points += available_points_per_question_index[index]
        end unless is_dropped

        total_fraction = total_points/worked_points if worked_points != 0.0

        {
          first_name: role.profile.first_name,
          last_name: role.profile.last_name,
          is_dropped: is_dropped,
          student_identifier: role.student.student_identifier,
          available_points: available_points,
          total_points: total_points,
          total_fraction: total_fraction,
          late_work_point_penalty: late_work_point_penalty,
          late_work_fraction_penalty: late_work_fraction_penalty,
          questions: student_questions
        }
      end.compact.sort_by { |student| [ student[:last_name], student[:first_name] ] }

      {
        id: period.id,
        name: period.name,
        question_headings: question_headings_array,
        late_work_fraction_penalty: task_plan.grading_template.late_work_penalty,
        num_questions_dropped: num_questions_dropped,
        points_dropped: points_dropped,
        students: students_array,
      }
    end
  end
end
