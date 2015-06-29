require_relative 'demo_base'

class Demo002 < DemoBase

  lev_routine

  protected


  def exec(print_logs: true, book_version: :latest, random_seed: nil)

    set_print_logs(print_logs)
    set_random_seed(random_seed)

    # Choose an anchor date that we will eventually travel to, and set all
    # other dates relative to it.  Make sure to reset to real time before
    # using "Time.now" in computing the anchor date.

    Timecop.return_all
    noon_today = Time.now.noon

    due=Array.new(4)
    due[3] = standard_due_at(school_day_on_or_before(noon_today))
    due[2] = standard_due_at(school_day_on_or_before(due[3] - 2.days))
    due[1] = standard_due_at(school_day_on_or_before(due[2] - 2.days))
    due[0] = standard_due_at(school_day_on_or_before(due[1] - 2.days))

    create_biology_assignments( find_course('Biology I'), due )
    create_physics_assignments( find_course('Physics I'), due )

  end

  def find_course(name)
    CourseProfile::Models::Profile.where(name: name).first!.course
  end

  def create_biology_assignments(course, due_at)
    periods = course.periods
    responses_list = new_responses_list(
      assignment_type: :reading,
      step_types: %w( r r i e r r e v e e r r i e r r e v e e ),
      entries: [
                  98,
                  67,
                  55,
                  77,
                  88,
                  %w( 1 1 1 1 1 1 0 1 1 1 1 1 1 1 1 1 1 1 1 0 ),
                  :not_started,
                  78,
                  %w( 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 ),  # explicit example, could also be `100`
                  86,
                  100,
                  82,
                  71,
                  90,
                  78,
                  87,
                  :incomplete,
                  :incomplete,
                  90,
                  85
               ]
    )

    assign_ireading(course: course,
                    chapter_sections: [[1, 1, 0], [1, 1, 1], [1,1,2]],
                    title: 'Read Unit 1. The Chemistry of Life',
                    due_at: due_at[1],
                    to: periods).each_with_index do |ireading, index|

      work_task(task: ireading, responses: responses_list[index])

    end

  end

  def create_physics_assignments(course, due_at)

    periods = course.periods

    ### First Chapter 3 iReading
    #

    responses_list = new_responses_list(
      assignment_type: :reading,
      step_types: %w( r r i e r r e v e e ),
      entries: [
                  98,
                  67,
                  55,
                  77,
                  88,
                  %w( 1 1 1 1 1 1 0 1 1 1 ),
                  :not_started,
                  78,
                  %w( 1 1 1 1 1 1 1 1 1 1 ),  # explicit example, could also be `100`
                  86,
                  100,
                  82,
                  71,
                  90,
                  78,
                  87,
                  :incomplete,
                  :incomplete,
                  90,
                  85
               ]
    )

    assign_ireading(course: course,
                    chapter_sections: [[3, 0], [3, 1]],
                    title: 'Read 3.1 Acceleration Pt1',
                    due_at: due_at[0],
                    to: periods).each_with_index do |ireading, index|

      work_task(task: ireading, responses: responses_list[index])

    end

    ### Second Chapter 3 iReading
    #

    responses_list = new_responses_list(
      assignment_type: :reading,
      step_types: %w( r i e r r e r r r e r e e e ),
      entries: [
                  94,
                  %w( 1 1 0 1 1 0 1 1 1 1 1 1 0 1 ),
                  40,
                  %w( 1 1 1 1 1 1 1 1 1 1 1 1 0 1 ),
                  60,
                  :incomplete,
                  :not_started,
                  72,
                  %w( 1 1 1 1 1 1 1 1 1 1 1 1 0 1 ),  # explicit example, could also be `100`
                  80,
                  100,
                  %w( 1 1 1 1 1 1 1 1 1 1 1 1 0 1 ),
                  %w( 1 1 0 1 1 1 1 1 1 0 1 1 0 1 ),
                  %w( 1 1 1 1 1 1 1 1 1 1 1 1 0 0 ),
                  79,
                  %w( 1 1 0 1 1 0 1 1 1 1 1 0 0 0 ),
                  :incomplete,
                  :incomplete,
                  %w( 1 1 1 1 1 1 1 1 1 1 1 1 0 1 ),
                  %w( 1 1 1 1 1 0 1 1 1 1 1 1 0 0 )
               ]
    )

    assign_ireading(course: course,
                    chapter_sections: [[3, 2]],
                    title: 'Read 3.2 Acceleration Pt2',
                    due_at: due_at[1],
                    to: periods).each_with_index do |ireading, index|

      work_task(task: ireading, responses: responses_list[index])

    end

    ### First Chapter 3 HW
    #

    responses_list = new_responses_list(
      assignment_type: :homework,
      step_types: %w( e e e e e e e e e e e ),
      entries: [
                  90,
                  87,
                  98,
                  %w( 1 1 1 1 1 0 0 1 1 1 1 ),
                  88,
                  :not_started,
                  :not_started,
                  :not_started,
                  100,
                  %w( 1 0 0 1 1 0 0 1 1 0 1 ),
                  100,
                  86,
                  %w( 1 1 1 1 1 0 0 1 1 0 1 ),
                  89,
                  %w( 0 1 0 1 0 0 0 1 0 0 0 ),
                  93,
                  :incomplete,
                  :incomplete,
                  98,
                  23
               ]
    )

    assign_homework(course: course,
                    chapter_sections: [[3, 0], [3, 1], [3, 2]],
                    title: 'HW Chapter 3 Acceleration',
                    num_exercises: 10,
                    due_at: due_at[2],
                    to: periods).each_with_index do |hw, index|

      work_task(task: hw, responses: responses_list[index])

    end

    ### First Chapter 4 iReading
    #

    responses_list = new_responses_list(
      assignment_type: :reading,
      step_types: %w( r r r v e i e e e e ),
      entries: [
                  94,
                  88,
                  60,
                  :incomplete,
                  84,
                  :incomplete,
                  92,
                  82,
                  %w( 1 1 1 1 0 1 1 1 0 1 ),
                  %w( 1 1 1 1 1 1 0 1 0 1 ),
                  100,
                  87,
                  %w( 1 1 1 1 0 1 0 0 0 1 ),
                  82,
                  :incomplete,
                  :not_started,
                  :not_started,
                  %w( 1 1 1 1 0 1 1 1 0 1 ),
                  88,
                  %w( 1 1 1 1 0 1 1 1 0 1 ),
               ]
    )

    assign_ireading(course: course,
                    chapter_sections: [[4, 0], [4, 1], [4, 2]],
                    title: 'Read 4.1-4.2 Force & Motion Pt1',
                    due_at: due_at[3],
                    to: periods).each_with_index do |ireading, index|

      work_task(task: ireading, responses: responses_list[index])

    end

  end

  def school_day_on_or_before(time)
    while time.sunday? || time.saturday?
      time = time.yesterday
    end
    time
  end

  def standard_due_at(time)
    time.midnight + 7.hours
  end

end
