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

      in_parallel(content.assignments.reject(&:draft)) do | assignments, initial_index |
        assignments.each do | assignment |
          work_assignment(content, assignment)
        end
      end

      in_parallel(get_auto_assignments(content).flatten) do | auto_assignments, initial_index |
        auto_assignments.each do | auto_assignment |
          work_assignment(content, auto_assignment)
        end
      end

    end

    wait_for_parallel_completion

  end

  def work_assignment(content, assignment)
    task_plan = Tasks::Models::TaskPlan.where(owner: content.course, title: assignment.title)
                .order(created_at: :desc).first!

    tasks_profile = build_tasks_profile(
      students: assignment.periods.flat_map{ |period| period.students.map(&:to_a) },
      assignment_type: assignment.type.to_sym,
      step_types: assignment.step_types,
    )
    log("Working assignment: #{assignment.title}")
    task_plan.tasks.preload([{taskings: {role: {user: {profile: :account}}}},
                             {task_steps: [:tasked, :task]}])
      .each_with_index do | task, index |
      user = task.taskings.first.role.user
      profile = tasks_profile[ user.profile.id ]

      unless profile
        raise "#{assignment.title} period #{period.id} has no responses for task #{index} for user #{user.profile.id} #{user.username}"
      end
      lateness = assignment.late ? assignment.late[profile.initials] : nil
      worked_at = task.due_at + (lateness ? lateness : -60)

      Timecop.freeze(worked_at) do
        work_task(task: task, responses: profile.responses)
      end
    end
  end


end
