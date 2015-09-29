require_relative 'demo_base'
require_relative 'content_configuration'

# Adds students to the course periods, assigns Sets up the periods and students for a course
# and then generates activity for them

# Dead ends to fixing circular dependancy errors

# require 'content/pool'
# require 'course_membership/models/period'
# require 'content/models/exercise'

class DemoTasks < DemoBase

  lev_routine

  protected

  def exec(book: :all, print_logs: true, random_seed: nil)
    set_print_logs(print_logs)
    set_random_seed(random_seed)

    Thread::abort_on_exception = true

    ContentConfiguration[book.to_sym].each do | content |

      in_parallel(content.assignments) do | assignments, initial_index |
        assignments.each do | assignment |
          create_assignment(content, assignment)
        end
      end

      in_parallel(content.auto_assign) do | auto_assigns, initial_index |
        auto_assigns.each do | settings |
          each_from_auto_assignment(content, settings) do | assignment |
            create_assignment(content, assignment)
          end
        end
      end

    end

    wait_for_parallel_completion

    Timecop.return_all
  end

  def create_assignment(content, assignment)
    log("Creating #{assignment.type} #{assignment.title} for course #{content.course_name}")

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
    # Draft plans do not undergo distribution
    if assignment.draft
      log("  Is a draft, skipping distributing")
    else
      log("  Distributing tasks")
      distribute_tasks(task_plan: task_plan)
    end
  end


end
