class CalculateTaskPlanStats

  lev_routine express_output: :stats

  protected

  def exercise_steps_for_page_id(page_id)
    page_los = Content::GetLos[page_ids: page_id]
    @plan.tasks.collect do |task|
      task.task_steps.select do |ts|
        ts.tasked_type.ends_with?("TaskedExercise") && (ts.tasked.los & page_los).any?
      end
    end.flatten
  end

  def answer_stats_for_tasked_exercises(tasked_exercises)
    tasked_exercises.first.answer_ids.collect do |answer_id|
      {
        id: answer_id,
        selected_count: tasked_exercises.select{ |te| te.answer_id == answer_id && \
                                                      te.completed? }.count
      }
    end
  end

  def exercise_stats_for_steps(steps)
    tasked_exercises = steps.collect{ |s| s.tasked }
    urls = Set.new(steps.collect{ |s| s.tasked.url })
    tasked_exercises = steps.collect{ |s| s.tasked }
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

  def page_stats_for_steps(steps)
    role_ids = steps.each_with_object([]){ |step, collection|
      step.task.taskings.each{ |tasking| collection << tasking.entity_role_id }
    }.uniq
    completed = steps.select { |ts| ts.completed? }
    correct_count = completed.count{|step| step.tasked.is_correct? }
    stats = {
      student_count: role_ids.length,
      correct_count: correct_count,
      incorrect_count: completed.length - correct_count
    }
    stats[:exercises] = exercise_stats_for_steps(steps) if @details
    stats
  end

  def generate_page_stats(page, include_previous=false)
    stats = {
      id:     page.id,
      number: page.number,
      title:  page.title
    }
    # find all the exercise task steps for the page number
    steps = exercise_steps_for_page_id(page.id)
    stats.merge page_stats_for_steps(steps)
  end

  def task_plan_pages
    if @plan.settings && @plan.settings['page_ids']
      Content::GetPagesAttributes.call(page_ids: @plan.settings['page_ids']).outputs.pages
    else
      []
    end
  end

  def generate_spaced_practice_stats
    # spaced exercises do not have pages
    stats = {
      id:     0000,
      number: 0000,
      title:  ""
    }
    steps = exercise_steps_for_page_id(nil)
    [ stats.merge(page_stats_for_steps(steps)) ]
  end

  def get_gradable_taskeds(task)
    task.task_steps.select do |ts|
      # Gradable steps are TaskedExercise that are marked as completed
      ts.tasked_type.ends_with?("TaskedExercise") && ts.completed?
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

      current_pages: task_plan_pages.map{|page|
        generate_page_stats(page)
      },

      spaced_pages: generate_spaced_practice_stats
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
