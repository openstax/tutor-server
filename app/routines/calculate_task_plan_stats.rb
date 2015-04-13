class CalculateTaskPlanStats

  lev_routine express_output: :stats

  protected

  def completed_exercises_for_page_id(page_id)
    @plan.tasks.inject([]) do |collection,task|
      collection + task.task_steps.find_all{|ts|
        ts.tasked_type.ends_with?("TaskedExercise") && ts.page_id == page_id
      }
    end
  end

  def page_stats_for_steps(steps)
    role_ids = steps.each_with_object([]){ |step, collection|
      step.task.taskings.each{|tasking| collection << tasking.entity_role_id }
    }.uniq
    completed = steps.select {|ts| ts.completed? }
    stats = {
      student_count: role_ids.length,
      correct_count: completed.count{|step| step.tasked.is_correct? }
    }
    stats[:incorrect_count] = completed.length - stats[:correct_count]
    stats
  end


  def generate_page_stats(page, include_previous=false)
    stats = {
      page: {
        id:     page.id,
        number: page.number,
        title:  page.title
      }
    }
    # find all the exercise task steps for the page number
    steps = completed_exercises_for_page_id(page.id)
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
    # spaced excercises do not have pages
    stats = {
      page: {
        id:     0000,
        number: 0000,
        title:  ""
      }
    }
    steps = completed_exercises_for_page_id(nil)
    [ stats.merge(page_stats_for_steps(steps)) ]
  end

  def get_gradable_taskeds(task)
    task.task_steps.select do |ts|
      # Gradable steps are TaskedExercise that are marked as completed
      ts.tasked_type.demodulize == 'TaskedExercise' && ts.completed?
    end.collect{ |ts| ts.tasked }
  end

  def get_task_grade(task)
    gradables = get_gradable_taskeds(task)
    return if gradables.blank?
    gradables.select{|g| g.is_correct?}.count/gradables.count
  end

  def mean_grade_percentage(tasks)
    grades_array = tasks.collect{ |task| get_task_grade(task) }.compact
    sum_of_grades = grades_array.inject(:+)
    return nil if sum_of_grades.nil?
    (sum_of_grades*100.0/grades_array.count).round
  end

  def generate_course_stat_data
    tasks = @plan.tasks.preload(task_steps: :tasked)
                       .includes(:taskings).to_a
    {
      mean_grade_percentage: mean_grade_percentage(tasks),

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

  def exec(plan:nil)
    @plan = plan

    outputs[:stats] = Hashie::Mash.new(
      {
        course: generate_course_stat_data,
        periods: [] # Awaiting implementation of periods subsystem
      }
    )
  end

end
