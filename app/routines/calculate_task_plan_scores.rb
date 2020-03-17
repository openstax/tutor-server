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
      :id, :correct_answer_id, :answer_id
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
      question_headings_array = exercise_steps.each_with_index.map do |_, index|
        { title: "Q#{index + 1}", type: 'MCQ' }
      end
      available_points_per_question = exercise_steps.each_with_index.map do |_, index|
        available_points_per_question_index[index]
      end
      available_points = available_points_per_question.sum
      available_points_hash = {
        name: 'Available Points',
        total_points: available_points,
        total_fraction: 1.0,
        points_per_question: available_points_per_question
      }

      if task_plan.type == 'homework'
        expected_num_questions = task_plan.settings.fetch(:exercises).map do |exercise|
          exercise.points.size
        end.sum + task_plan.settings.fetch('exercises_count_dynamic', 3)
        actual_num_questions = most_common_tasks.first.actual_and_placeholder_exercise_count
        num_questions_dropped = expected_num_questions - actual_num_questions
      else
        num_questions_dropped = 0
      end
      points_dropped = num_questions_dropped.to_f

      question_points = []
      students_array = tasks.each_with_index.map do |task, student_index|
        role = task.taskings.first.role
        student = role.student
        next if student.nil?

        account = task.taskings.first.role.profile.account

        exercise_steps = task.task_steps.filter { |step| step.exercise? || step.placeholder? }
        next if exercise_steps.empty?

        is_dropped = student.dropped? || student.period.archived?

        student_available_points = exercise_steps.size.times.map do |index|
          available_points_per_question_index[index]
        end.sum
        points_per_question = exercise_steps.each_with_index.map do |task_step, index|
          next 0.0 if task_step.placeholder?

          tasked = tasked_exercise_by_id[task_step.tasked_id]
          tasked.is_correct? ? available_points_per_question_index[index] : 0.0
        end

        total_points_without_lateness = points_per_question.sum

        late_work_fraction_penalty = task.late_work_penalty
        late_work_point_penalty = late_work_fraction_penalty * total_points_without_lateness

        total_points = total_points_without_lateness - late_work_point_penalty
        total_fraction = total_points/available_points


        points_per_question.each_with_index do |points, index|
          question_points[index] ||= []
          question_points[index] << points
        end unless is_dropped

        {
          name: account.name,
          first_name: account.first_name,
          last_name: account.last_name,
          is_dropped: is_dropped,
          available_points: student_available_points,
          total_points: total_points,
          total_fraction: total_fraction,
          late_work_point_penalty: late_work_point_penalty,
          late_work_fraction_penalty: late_work_fraction_penalty,
          points_per_question: points_per_question
        }
      end.compact.sort_by { |student| [ student[:last_name], student[:first_name] ] }

      average_points_per_question = question_points.map do |points_per_question|
        points_per_question.sum/points_per_question.size
      end
      num_students = students_array.size
      average_points = students_array.map { |student| student[:total_points] }.sum/num_students
      average_score_hash = {
        name: 'Average Score',
        total_points: average_points,
        total_fraction: [ average_points/available_points, 1.0 ].min,
        points_per_question: average_points_per_question
      }

      {
        id: period.id,
        name: period.name,
        question_headings: question_headings_array,
        late_work_fraction_penalty: task_plan.grading_template.late_work_penalty,
        available_points: available_points_hash,
        num_questions_dropped: num_questions_dropped,
        points_dropped: points_dropped,
        students: students_array,
        average_score: average_score_hash
      }
    end
  end
end
