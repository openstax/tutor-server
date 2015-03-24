class CalculateIReadingStats

  lev_routine

  protected

  def completed_exercises_for_page_id(page_id)
    @plan.tasks.inject([]) do |collection,task|
      collection + task.task_steps.find_all{|ts|
        ts.tasked_type == "TaskedExercise" && ts.page_id == page_id
      }
    end
  end

  def page_stats_for_steps(steps)
    user_ids = steps.each_with_object([]){ |step, collection|
      step.task.taskings.each{|tasking| collection << tasking.user_id }
    }.uniq
    completed = steps.select {|ts| ts.completed? }
    stats = {
      student_count: user_ids.length,
      correct_count: completed.count{|step| step.tasked.correct_answer_id == step.tasked.answer_id }
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
      Content::Api::GetPagesAttributes.call(page_ids: @plan.settings['page_ids']).outputs.pages
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

  def generate_course_stat_data
    {

      total_count: @plan.tasks.count,

      complete_count: @plan.tasks.select{|task|
        task.task_steps.all?{| ts | ts.completed? }
      }.length,

      partially_complete_count: @plan.tasks.select{|task|
        task.task_steps.any?{| ts | ts.completed? }
      }.length,

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
