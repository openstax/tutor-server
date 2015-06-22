class CalculateTaskPlanStats

  lev_routine express_output: :stats

  uses_routine Content::Routines::SearchPages, as: :search_pages

  protected

  def answer_stats_for_tasked_exercises(tasked_exercises)
    tasked_exercises.first.answer_ids.each_with_object({}) do |answer_id, hash|
      hash[answer_id] = tasked_exercises.select{ |te| te.answer_id == answer_id && \
                                                      te.completed? }.count
    end
  end

  def exercise_stats_for_tasked_exercises(tasked_exercises)
    urls = Set.new(tasked_exercises.collect{ |te| te.url })
    urls.collect do |url|
      selected_tasked_exercises = tasked_exercises.select{ |te| te.url == url }
      completed_tasked_exercises = selected_tasked_exercises.select{ |te| te.completed? }
      exercise = OpenStax::Exercises::V1::Exercise.new(content: selected_tasked_exercises.first.content)
      answer_stats = answer_stats_for_tasked_exercises(selected_tasked_exercises)

      {
        content: exercise.content_with_answer_stats(answer_stats),
        answered_count: completed_tasked_exercises.count
      }
    end
  end

  def page_stats_for_tasked_exercises(tasked_exercises)
    completed = tasked_exercises.select { |te| te.completed? }

    some_completed_role_ids = completed.each_with_object([]){ |tasked_exercise, collection|
      tasked_exercise.task_step.task.taskings.each{ |tasking|
        collection << tasking.entity_role_id
      }
    }.uniq

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
      chapter_section: page.chapter_section
    }

    stats.merge page_stats_for_tasked_exercises(tasked_exercises)
  end

  def get_gradable_taskeds(task)
    task.task_steps.select do |ts|
      # Gradable steps are TaskedExercise that are marked as completed
      ts.tasked.exercise? && ts.completed?
    end.collect{ |ts| ts.tasked }
  end

  def get_task_grade(task)
    gradables = get_gradable_taskeds(task)
    return if gradables.blank?
    gradables.select{|g| g.is_correct?}.count.to_f/gradables.count
  end

  def mean_grade_percent(tasks)
    grades_array = tasks.collect{ |task| get_task_grade(task) }.compact
    sum_of_grades = grades_array.inject(:+)
    return nil if sum_of_grades.nil?
    (sum_of_grades*100.0/grades_array.count).round
  end

  def get_tasked_exercises_from_task_steps(task_steps)
    task_steps.flatten.collect{ |ts| ts.tasked }.select{ |t| t.exercise? }
  end

  def get_page_for_tasked_exercise(tasked_exercise)
    run(:search_pages, tag: tasked_exercise.los).outputs.items.first
  end

  def group_tasked_exercises_by_pages(tasked_exercises)
    tasked_exercises.group_by{ |te| get_page_for_tasked_exercise(te) }
  end

  def generate_page_stats_for_task_steps(task_steps)
    tasked_exercises = get_tasked_exercises_from_task_steps(task_steps)
    page_hash = group_tasked_exercises_by_pages(tasked_exercises)
    page_hash.collect{ |page, tasked_exercises| generate_page_stats(page, tasked_exercises) }
  end

  def no_period
    @no_period ||= CourseMembership::Models::Period.new(name: 'None')
  end

  def generate_period_stat_data
    tasks = @plan.tasks.preload(task_steps: :tasked)
                       .includes(taskings: {role: {students: :period}}).to_a
    grouped_tasks = tasks.group_by do |tt|
      tt.taskings.first.role.students.first.try(:period) || no_period
    end
    grouped_tasks.collect do |period, period_tasks|
      Hashie::Mash.new(
        period_id: period.id,

        name: period.name,

        mean_grade_percent: mean_grade_percent(period_tasks),

        total_count: period_tasks.count,

        complete_count: period_tasks.count{|task|
          task.task_steps.all?{| ts | ts.completed? }
        },

        partially_complete_count: period_tasks.count{|task|
          task.task_steps.any?{| ts | ts.completed? } &&
            !task.task_steps.all?{| ts | ts.completed? }
        },

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
