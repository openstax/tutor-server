require_relative 'demo_base'
require_relative 'demo/content_configuration'

class Demo002 < DemoBase

  lev_routine

  protected

  def exec(book: :all, print_logs: true, random_seed: nil)
    set_print_logs(print_logs)
    set_random_seed(random_seed)

    ContentConfiguration[book.to_sym].each do | content |
      content.assignments.each do | assignment |
        log("Creating #{assignment.type} #{assignment.title} for course #{content.course_name}")
        responses_list = new_responses_list(
          assignment_type: assignment.type.to_sym,
          step_types: assignment.step_types,
          entries: assignment.scores )

        if assignment.type == 'reading'
          create_and_work_reading(content, assignment, responses_list)
        else
          create_and_work_homework(content, assignment, responses_list)
        end
      end
    end

    Timecop.return_all
  end

  def create_and_work_homework(content, assignment, responses_list)
    assign_homework(course: content.course,
                    chapter_sections: assignment.chapter_sections,
                    title: assignment.title,
                    num_exercises: assignment.num_exercises,
                    due_at: assignment.due_at,
                    to: content.periods).each_with_index do |hw, index|

      work_task(task: hw, responses: responses_list[index])
    end
  end

  def create_and_work_reading(content, assignment, responses_list)
    assign_ireading(course: content.course,
                    chapter_sections: assignment.chapter_sections,
                    title: assignment.title,
                    due_at: assignment.due_at,
                    to: content.periods).each_with_index do |ireading, index|

      work_task(task: ireading, responses: responses_list[index])
    end

  end

end
