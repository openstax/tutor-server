require_relative 'demo_base'
require_relative 'content_configuration'

# Adds students to the course periods, assigns Sets up the periods and students for a course
# and then generates activity for them
class DemoTasks < DemoBase

  lev_routine

  protected

  def exec(book: :all, print_logs: true, random_seed: nil)
    set_print_logs(print_logs)
    set_random_seed(random_seed)

    ContentConfiguration[book.to_sym].each do | content |
      content.assignments.each do | assignment |

        log("Creating #{assignment.type} #{assignment.title} for course #{content.course_name} (#{assignment.step_types.length} steps)")

        course = content.course
        task_plan = if assignment.type == 'reading'
                      assign_ireading(course: course,
                                      book_locations: assignment.book_locations,
                                      title: assignment.title)
                    else
                      assign_homework(course: course,
                                      book_locations: assignment.book_locations,
                                      title: assignment.title,
                                      num_exercises: assignment.num_exercises)
                    end

        assignment.periods.each do | period |
          log("  Adding tasking plan for period #{period.id}")
          course_period = course.periods.where(name: content.get_period(period.id).name).first!
          add_tasking_plan(task_plan: task_plan,
                           to: course_period,
                           opens_at: period.opens_at,
                           due_at: period.due_at)
        end

        log("  Distributing tasks")
        task_plan = Tasks::Models::TaskPlan.where(owner: content.course, title: assignment.title)
                                           .order(created_at: :desc).first!
        distribute_tasks(task_plan: task_plan)

      end
    end

    Timecop.return_all
  end


end
