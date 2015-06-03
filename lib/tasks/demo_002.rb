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
    anchor_date = Time.now.next_week(:tuesday).advance(hours: 15)

    monday_1    = anchor_date - 8.days
    wednesday_1 = anchor_date - 6.days
    friday_1    = anchor_date - 4.days
    monday_2    = anchor_date - 1.day

    log("Assignments will be due in the week+ leading up to #{anchor_date}.")

    course = Entity::Course.last

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
                  :incomplete,
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
                    title: 'Reading 3.0 - 3.1',
                    due_at: monday_1).each_with_index do |ireading, index|

      work_task(task: ireading, responses: responses_list[index])

    end

    ### Second Chapter 3 iReading
    #

    responses_list = new_responses_list(
      assignment_type: :reading,
      step_types: %w( r i e r r e r r r e r e e e ),
      entries: [
                  94,
                  79,
                  40,
                  80,
                  60,
                  :incomplete,
                  :not_started,
                  72,
                  %w( 1 1 1 1 1 1 1 1 1 1 1 1 1 1 ),  # explicit example, could also be `100`
                  80,
                  100,
                  88,
                  73,
                  80,
                  79,
                  40,
                  :incomplete,
                  :incomplete,
                  87,
                  86
               ]
    )

    assign_ireading(course: course,
                    chapter_sections: [[3, 2]],
                    title: 'Reading 3.2',
                    due_at: wednesday_1).each_with_index do |ireading, index|

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
                  70,
                  88,
                  :not_started,
                  :not_started,
                  :not_started,
                  100,
                  82,
                  100,
                  86,
                  81,
                  89,
                  81,
                  93,
                  :incomplete,
                  :incomplete,
                  98,
                  68
               ]
    )

    assign_homework(course: course,
                    chapter_sections: [[3, 0], [3, 1], [3, 2]],
                    num_exercises: 10,
                    due_at: friday_1).each_with_index do |hw, index|

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
                  100,
                  81,
                  100,
                  87,
                  59,
                  82,
                  :incomplete,
                  :not_started,
                  :not_started,
                  66,
                  88,
                  89
               ]
    )

    assign_ireading(course: course,
                    chapter_sections: [[4, 0], [4, 1], [4, 2]],
                    title: 'Reading 4.0 - 4.2',
                    due_at: monday_2).each_with_index do |ireading, index|

      work_task(task: ireading, responses: responses_list[index])

    end

    log("Setting the time to #{anchor_date} which may or may not stick depending on which environment this is.")
    log("-- if the time didn't stick, log in as the administrator and modify the time in the admin console.")
    Timecop.travel_all(anchor_date)

  end
end
