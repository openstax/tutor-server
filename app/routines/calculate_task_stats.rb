class CalculateTaskStats

  lev_routine express_output: :stats

  uses_routine Role::GetUsersForRoles, as: :get_users_for_roles

  protected

  def assignee_names_for(task)
    (@names ||= {})[task.id] ||= begin
      roles = task.taskings.map(&:role)
      users = run(:get_users_for_roles, roles).outputs.users
      users.map(&:name)
    end
  end

  def compute_answer_stats(tasked_exercises)
    tasked_exercises.each_with_object(
      {
        selected_count: Hash.new(0)
      }
    ) do |tasked_exercise, stats|
      stats[:selected_count][tasked_exercise.answer_id] += 1 if tasked_exercise.completed?
    end
  end

  def average_step_number(taskeds)
    taskeds.map{ |tasked| tasked.task_step.number }.reduce(0, :+) / Float(taskeds.size)
  end

  def exercise_stats_for_tasked_exercises(tasked_exercises)
    tasked_exercises.group_by{ |te| te.exercise }.map do |exercise, tasked_exercises|

      {
        content: exercise.content,

        question_stats: tasked_exercises.group_by(&:question_id)
                                        .map do |question_id, question_tasked_exercises|

          answer_stats = compute_answer_stats(question_tasked_exercises)
          all_answer_ids = question_tasked_exercises.first.answer_ids
          completed_question_tasked_exercises = question_tasked_exercises.select(&:completed?)

          {
            question_id: question_id,

            answered_count: completed_question_tasked_exercises.count,

            answer_stats: all_answer_ids.map do |answer_id|
              {
                answer_id: answer_id,
                selected_count: answer_stats[:selected_count][answer_id] || 0
              }
            end,

            answers: completed_question_tasked_exercises.map do |te|
              {
                student_names: assignee_names_for(te.task_step.task),
                free_response: te.free_response,
                answer_id: te.answer_id
              }
            end
          }
        end,

        average_step_number: average_step_number(tasked_exercises)
      }
    end.sort_by do |exercise_stats|
      exercise_stats[:average_step_number]
    end
  end

  def page_stats_for_tasked_exercises(tasked_exercises)
    completed = tasked_exercises.select{ |te| te.completed? }

    some_completed_role_ids = completed.map do |tasked_exercise|
      tasked_exercise.task_step.task.taskings.map(&:entity_role_id)
    end.flatten.uniq

    correct_count = completed.count{ |te| te.is_correct? }
    incorrect_count = completed.length - correct_count

    trouble = (incorrect_count > correct_count) && (completed.size > 0.25*tasked_exercises.size)

    stats = {
      student_count: some_completed_role_ids.length,
      correct_count: correct_count,
      incorrect_count: incorrect_count,
      trouble: trouble
    }
    stats[:exercises] = exercise_stats_for_tasked_exercises(tasked_exercises) if @details
    stats
  end

  def generate_page_stats(page, tasked_exercises, include_previous=false)
    stats = {
      id:              page.id,
      title:           page.title,
      chapter_section: page.book_location
    }

    stats.merge page_stats_for_tasked_exercises(tasked_exercises)
  end

  def get_task_grade(task)
    return if task.completed_exercise_steps_count == 0
    task.correct_exercise_steps_count.to_f / task.completed_exercise_steps_count
  end

  def mean_grade_percent(tasks)
    grades_array = tasks.map{ |task| get_task_grade(task) }.compact
    sum_of_grades = grades_array.inject(:+)
    return nil if sum_of_grades.nil?
    (sum_of_grades*100.0/grades_array.count).round
  end

  def get_tasked_exercises_from_task_steps(task_steps)
    tasked_exercise_ids = task_steps.flatten.select(&:exercise?).map(&:tasked_id)
    Tasks::Models::TaskedExercise.joins { task_step }
                                 .where { id.in tasked_exercise_ids }
                                 .preload([{exercise: :page},
                                           {task_step: {task: {taskings: :role}}}]).to_a
  end

  def group_tasked_exercises_by_pages(tasked_exercises)
    tasked_exercises.group_by{ |te| te.exercise.page }
  end

  def generate_page_stats_for_task_steps(task_steps)
    page_hash = group_tasked_exercises_by_pages(
      get_tasked_exercises_from_task_steps(task_steps)
    )

    page_hash.map{ |page, tasked_exercises| generate_page_stats(page, tasked_exercises) }
             .sort_by{ |page_stats| page_stats[:chapter_section] }
  end

  def generate_period_stat_data
    tasks = @tasks.preload([:task_steps, {taskings: :period}]).to_a

    grouped_tasks = tasks.group_by do |task|
      task.taskings.first.try(:period)
    end

    grouped_tasks.map do |period, period_tasks|
      next if period.nil? || period.deleted?

      current_page_stats = generate_page_stats_for_task_steps(
                             period_tasks.map{ |t| t.core_task_steps + t.personalized_task_steps }
                           )
      spaced_page_stats = generate_page_stats_for_task_steps(
                            period_tasks.map(&:spaced_practice_task_steps)
                          )

      Hashie::Mash.new(
        period_id: period.id,

        name: period.name,

        mean_grade_percent: mean_grade_percent(period_tasks),

        total_count: period_tasks.count,

        complete_count: period_tasks.count(&:completed?),

        partially_complete_count: period_tasks.count(&:in_progress?),

        current_pages: current_page_stats,

        spaced_pages: spaced_page_stats,

        # For now personalized pages are the same as current pages, so it's fine to include them
        trouble: (current_page_stats + spaced_page_stats).any?{ |page_stats| page_stats[:trouble] }
      )
    end.compact
  end

  def exec(tasks:, details: false)
    @tasks = tasks
    @details = details

    outputs[:stats] = generate_period_stat_data
  end

end
