class CalculateTaskPlanStats

  lev_routine express_output: :stats

  uses_routine Content::Routines::SearchPages, as: :search_pages

  protected

  def answer_stats_for_tasked_exercises(tasked_exercises)
    tasked_exercises.first.answer_ids.collect do |answer_id|
      {
        id: answer_id,
        selected_count: tasked_exercises.select{ |te| te.answer_id == answer_id && \
                                                      te.completed? }.count
      }
    end
  end

  def exercise_stats_for_tasked_exercises(tasked_exercises)
    urls = Set.new(tasked_exercises.collect{ |te| te.url })
    urls.collect do |url|
      selected_tasked_exercises = tasked_exercises.select{ |te| te.url == url }
      completed_tasked_exercises = selected_tasked_exercises.select{ |te| te.completed? }

      {
        content_json: selected_tasked_exercises.first.content,
        answered_count: completed_tasked_exercises.count,
        answers: answer_stats_for_tasked_exercises(selected_tasked_exercises)
      }
    end
  end

  def page_stats_for_tasked_exercises(tasked_exercises)
    role_ids = tasked_exercises.each_with_object([]){ |tasked_exercise, collection|
      tasked_exercise.task_step.task.taskings.each{ |tasking|
        collection << tasking.entity_role_id
      }
    }.uniq
    completed = tasked_exercises.select { |te| te.completed? }
    correct_count = completed.count{ |te| te.is_correct? }
    stats = {
      student_count: role_ids.length,
      correct_count: correct_count,
      incorrect_count: completed.length - correct_count
    }
    stats[:exercises] = exercise_stats_for_tasked_exercises(tasked_exercises) if @details
    stats
  end

  def generate_page_stats(page, tasked_exercises, include_previous=false)
    stats = {
      id:     page.id,
      number: page.number,
      title:  page.title
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

  def generate_course_stat_data
    tasks = @plan.tasks.preload(task_steps: :tasked)
                       .includes(:taskings).to_a
    {
      mean_grade_percent: mean_grade_percent(tasks),

      total_count: tasks.count,

      complete_count: tasks.count{|task|
        task.task_steps.all?{| ts | ts.completed? }
      },

      partially_complete_count: tasks.count{|task|
        task.task_steps.any?{| ts | ts.completed? } &&
          !task.task_steps.all?{| ts | ts.completed? }
      },

      current_pages: generate_page_stats_for_task_steps(tasks.collect{ |t| t.core_task_steps }),

      spaced_pages: generate_page_stats_for_task_steps(
                      tasks.collect{ |t| t.spaced_practice_task_steps }
                    )
    }
  end

  def exec(plan:, details: false)
    @plan = plan
    @details = details

    outputs[:stats] = Hashie::Mash.new(
      {
        course: generate_course_stat_data,
        periods: [] # Awaiting implementation of periods subsystem
      }
    )
  end

end
