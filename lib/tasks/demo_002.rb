require_relative 'demo_base'
require_relative 'demo/content_configuration'

# Adds students to the course periods, assigns Sets up the periods and students for a course
# and then generates activity for them

class Demo002 < DemoBase

  lev_routine

  protected

  def exec(book: :all, print_logs: true, random_seed: nil)
    set_print_logs(print_logs)
    set_random_seed(random_seed)

    ContentConfiguration[book.to_sym].each do | content |
      content.assignments.each do | assignment |

        log("Creating #{assignment.type} #{assignment.title} for course #{content.course_name}")

        assignment.periods.each do | period |

          responses_list = new_responses_list(
            students: period.students,
            assignment_type: assignment.type.to_sym,
            step_types: assignment.step_types,
          )

          tasks = if assignment.type == 'reading'
                    create_and_work_reading(content, period, assignment, responses_list)
                  else
                    create_and_work_homework(content, period, assignment, responses_list)
                  end

          tasks.each_with_index do | task, index |
            user = task.taskings.first.role.user.user

            responses = responses_list[ user.profile.id ]
            unless responses
              binding.pry
              raise "#{assignment.title} period index #{period['index']} has no responses for task #{index} for user #{user.profile.id} #{user.username}"
            end
            work_task(task: task, responses: responses)
          end


        end
      end
    end

    Timecop.return_all
  end

  def create_and_work_homework(content, period, assignment, responses_list)
    assign_homework(course: content.course,
                    chapter_sections: assignment.chapter_sections,
                    title: assignment.title,
                    num_exercises: assignment.num_exercises,
                    to: content.course.periods.order(:created_at).at(period[:index]),
                    opens_at: period.opens_at,
                    due_at: period.due_at)
  end

  def create_and_work_reading(content, period, assignment, responses_list)
    assign_ireading(course: content.course,
                    to: content.course.periods.order(:created_at).at(period[:index]),
                    chapter_sections: assignment.chapter_sections,
                    title: assignment.title,
                    opens_at: period.opens_at,
                    due_at: period.due_at)
  end

end
