require_relative 'demo_base'
require_relative 'content_configuration'

# Adds students to the course periods, assigns Sets up the periods and students for a course
# and then generates activity for them
class DemoWork < DemoBase

  lev_routine

  disable_automatic_lev_transactions

  protected

  def exec(book: :all, print_logs: true, random_seed: nil)
    set_print_logs(print_logs)
    set_random_seed(random_seed)

    ContentConfiguration[book.to_sym].each do | content |

      in_parallel(content.assignments.reject(&:draft),
                  transaction: true) do | assignments, initial_index |
        assignments.each do | assignment |
          work_assignment(content, assignment)
        end
      end

      in_parallel(get_auto_assignments(content).flatten,
                  transaction: true) do | auto_assignments, initial_index |
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
    task_plan.tasks.preload([{taskings: {role: {profile: :account}}},
                             {task_steps: [:tasked, :task]}])
      .each_with_index do | task, index |

      profile = task.taskings.first.role.profile
      strategy = ::User::Strategies::Direct::User.new(profile)
      user = ::User::User.new(strategy: strategy)
      task_profile = tasks_profile[user.id]

      unless task_profile
        raise "#{assignment.title} period #{period.id} has no responses for task #{index} for user #{user.id} #{user.username}"
      end
      lateness = assignment.late ? assignment.late[task_profile.initials] : nil
      worked_at = task.due_at + (lateness ? lateness : -60)

      Timecop.freeze(worked_at) do
        work_task(task: task, responses: task_profile.responses)
      end
    end
  end


end
