require_relative 'demo_base'

if ActiveRecordQueryTrace.enabled
  logger = Logger.new(STDOUT)
  logger.info "ActiveRecord Query Trace is enabled! This will be way too slow!"
  logger.info "DISABLING ActiveRecord Query Trace"
  ActiveRecordQueryTrace.enabled = false
end

class Demo002 < DemoBase

  lev_routine

  protected

  def exec(print_logs: true, book_version: :latest, random_seed: nil)

    # TODO change to October date once Timecop better integrated
    # initial_date = Time.now # Chronic.parse("October 14, 2015")
    initial_date = (Time.now.midnight + 1.day) - (0.001).seconds

    log("Assignments will be due around #{initial_date}.")

    ### First Chapter 3 iReading
    #

    responses_list = new_responses_list(
      assignment_type: :reading,
      step_types: %w( r r i e r r r e v e e r i e e r r e r r r e r e e ),
      entries: [
                  98,
                  67,
                  55,
                  77,
                  88,
                  :incomplete,
                  :not_started,
                  78,
                  %w( 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 ),  # explicit example, could also be `100`
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

    course = Entity::Course.last
    assign_ireading(course: course,
                    chapter_sections: [[3, 0], [3, 1], [3, 2]],
                    title: 'Reading 3.0 - 3.2',
                    due_at: initial_date - 5.days).each_with_index do |ireading, index|

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
                    due_at: initial_date - 3.days).each_with_index do |hw, index|

      work_task(task: hw, responses: responses_list[index])

    end

    ### First Chapter 4 iReading
    #

    responses_list = new_responses_list(
      assignment_type: :reading,
      step_types: %w( r i e e ),
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
                    chapter_sections: [[4, 0], [4, 1]],
                    title: 'Reading 4.0 - 4.1',
                    due_at: initial_date - 0.days).each_with_index do |ireading, index|

      work_task(task: ireading, responses: responses_list[index])

    end

    ### First Chapter 4 HW
    #

    responses_list = new_responses_list(
      assignment_type: :homework,
      step_types: %w( e e e e e e e e e e ),
      entries: [
                 :incomplete,
                 :incomplete,
                 95,
                 72,
                 89,
                 70,
                 96,
                 87,
                 100,
                 84,
                 100,
                 83,
                 70,
                 88,
                 83,
                 90,
                 77,
                 76,
                 91,
                 85
               ]
    )

    assign_homework(course: course,
                    chapter_sections: [[4, 0], [4, 1]],
                    num_exercises: 8,
                    due_at: initial_date - 0.days).each_with_index do |hw, index|

      work_task(task: hw, responses: responses_list[index])

    end

  end
end
