class CalculateTaskPlanStats

  lev_routine express_output: :stats

  uses_routine Role::GetUsersForRoles, as: :get_users_for_roles

  uses_routine UserProfile::SearchProfiles, as: :search_profiles

  protected

  def answer_stats_for_tasked_exercises(tasked_exercises)
    tasked_exercises.first.answer_ids.each_with_object({}) do |answer_id, hash|
      hash[answer_id] = tasked_exercises.select{ |te| te.answer_id == answer_id && \
                                                      te.completed? }.count
    end
  end

  def exercise_stats_for_tasked_exercises(tasked_exercises)
    tasked_exercises.group_by{ |te| te.exercise }.collect do |exercise, tasked_exercises|
      average_step_number = tasked_exercises.map{ |te| te.task_step.number }
                                            .reduce(:+)/Float(tasked_exercises.size)
      completed_tasked_exercises = tasked_exercises.select{ |te| te.completed? }
      exercise_parser = OpenStax::Exercises::V1::Exercise.new(content: exercise.content)
      answer_stats = answer_stats_for_tasked_exercises(tasked_exercises)

      {
        content: exercise_parser.content_with_answer_stats(answer_stats),
        answered_count: completed_tasked_exercises.count,
        answers: completed_tasked_exercises.collect do |te|
          roles = te.task_step.task.taskings.collect{ |ts| ts.role }
          users = run(:get_users_for_roles, roles).outputs.users
          names = run(:search_profiles, search: users).outputs.profiles.items.collect(&:full_name)

          {
            student_names: names,
            free_response: te.free_response,
            answer_id: te.answer_id
          }
        end,
        average_step_number: average_step_number
      }
    end.sort_by do |exercise_stats|
      exercise_stats[:average_step_number]
    end
  end

  def page_stats_for_tasked_exercises(tasked_exercises)
    completed = tasked_exercises.select{ |te| te.completed? }

    some_completed_role_ids = completed.collect do |tasked_exercise|
      tasked_exercise.task_step.task.taskings.collect{ |tasking| tasking.entity_role_id }
    end.flatten.uniq

    correct_count = completed.count{ |te| te.is_correct? }
    stats = {
      student_count: some_completed_role_ids.length,
      correct_count: correct_count,
      incorrect_count: completed.length - correct_count
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
    grades_array = tasks.collect{ |task| get_task_grade(task) }.compact
    sum_of_grades = grades_array.inject(:+)
    return nil if sum_of_grades.nil?
    (sum_of_grades*100.0/grades_array.count).round
  end

  def get_tasked_exercises_from_task_steps(task_steps)
    tasked_exercise_ids = task_steps.flatten.select{ |t| t.exercise? }.collect{ |ts| ts.tasked_id }
    Tasks::Models::TaskedExercise.joins { task_step }
                                 .where { id.in tasked_exercise_ids }
                                 .eager_load([{exercise: :page},
                                              {task_step: {task: {taskings: :role}}}]).to_a
  end

  def group_tasked_exercises_by_pages(tasked_exercises)
    tasked_exercises.group_by{ |te| te.exercise.page }
  end

  def generate_page_stats_for_task_steps(task_steps)
    page_hash = group_tasked_exercises_by_pages(
      get_tasked_exercises_from_task_steps(task_steps)
    )

    page_hash.collect{ |page, tasked_exercises| generate_page_stats(page, tasked_exercises) }
             .sort_by{ |page_stats| page_stats[:chapter_section] }
  end

  def no_period
    @no_period ||= CourseMembership::Models::Period.new(name: 'None')
  end

  def generate_period_stat_data
    tasks = @plan.tasks.eager_load([:task_steps, {taskings: :period}]).to_a
    grouped_tasks = tasks.group_by do |tt|
      tt.taskings.first.try(:period) || no_period
    end
    grouped_tasks.collect do |period, period_tasks|
      Hashie::Mash.new(
        period_id: period.id,

        name: period.name,

        mean_grade_percent: mean_grade_percent(period_tasks),

        total_count: period_tasks.count,

        complete_count: period_tasks.count(&:completed?),

        partially_complete_count: period_tasks.count(&:in_progress?),

        current_pages: generate_page_stats_for_task_steps(
                         period_tasks.collect{ |t| t.core_task_steps }
                       ),

        spaced_pages: generate_page_stats_for_task_steps(
                        period_tasks.collect{ |t| t.spaced_practice_task_steps }
                      )
      )
    end
  end

  def exec(plan:, details: false)
    @plan = plan
    @details = details

    outputs[:stats] = generate_period_stat_data
  end

end
