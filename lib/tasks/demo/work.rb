require_relative 'demo_base'
require_relative 'content_configuration'

# Adds students to the course periods, assigns Sets up the periods and students for a course
# and then generates activity for them
class DemoWork < DemoBase

  lev_routine

  protected

  def exec(book: :all, print_logs: true, random_seed: nil)
    set_print_logs(print_logs)
    set_random_seed(random_seed)

    ContentConfiguration[book.to_sym].each do | content |
      content.assignments.each do | assignment |

        log("  Distributing tasks")
        task_plan = Tasks::Models::TaskPlan.where(owner: content.course, title: assignment.title).first!
        tasks = distribute_tasks(task_plan:task_plan)

        responses_list = new_responses_list(
          students: assignment.periods.map{|period| period.students.map(&:to_a) }.flatten(1),
          assignment_type: assignment.type.to_sym,
          step_types: assignment.step_types,
        )

        tasks.each_with_index do | task, index |
          user = task.taskings.first.role.user
          responses = responses_list[ user.profile.id ]
          unless responses
            raise "#{assignment.title} period #{period.id} has no responses for task #{index} for user #{user.profile.id} #{user.username}"
          end
          log("    Working task # #{index}")
          work_task(task: task, responses: responses)
        end

      end
    end

  end

end
