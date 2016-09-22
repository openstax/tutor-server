require_relative 'base'

# Adds students to the course periods, assigns Sets up the periods and students for a course
# and then generates activity for them
class Demo::Work < Demo::Base

  lev_routine

  disable_automatic_lev_transactions

  protected

  def exec(config: :all, print_logs: true, random_seed: nil)
    set_print_logs(print_logs)
    set_random_seed(random_seed)

    Demo::ContentConfiguration[config].each do | content |

      in_parallel(content.assignments.reject(&:draft),
                  transaction: true) do | assignments, initial_index |
        assignments.each do | assignment |
          work_tp_assignment(content, assignment) unless assignment.type == 'concept_coach'
        end
      end

      in_parallel(get_auto_assignments(content).flatten,
                  transaction: true) do | auto_assignments, initial_index |
        auto_assignments.each do | auto_assignment |
          work_tp_assignment(content, auto_assignment) \
            unless auto_assignment.type == 'concept_coach'
        end
      end

      in_parallel(content.course.students, transaction: true) do |students, initial_index|
        students.each{ |student| work_cc_assignments(student) }
      end
    end

    wait_for_parallel_completion

  end

  def work_tp_assignment(content, assignment)
    task_plan = Tasks::Models::TaskPlan.where(owner: content.course, title: assignment.title)
                                       .order(created_at: :desc).first!

    tasks_profile = build_tasks_profile(
      students: assignment.periods.flat_map{ |period| period.students.map(&:to_a) },
      assignment_type: assignment.type.to_sym,
      step_types: assignment.step_types,
    )
    log("Working assignment: #{assignment.title}")
    task_plan.tasks
             .preload([{taskings: {role: {profile: :account}}}, {task_steps: [:tasked, :task]}])
             .each_with_index do | task, index |

      task_profile = tasks_profile[task]

      unless task_profile
        raise "#{assignment.title} period #{period.id} has no responses for task #{
              index} for user #{user.id} #{user.username}"
      end
      lateness = assignment.late ? assignment.late[task_profile.initials] : nil
      worked_at = task.due_at + (lateness ? lateness : -60)

      Timecop.freeze(worked_at) do
        work_task(tasks_profile: tasks_profile, task: task)
      end
    end
  end

  def work_cc_assignments(student)
    user = User::User.new(strategy: student.role.profile.wrap)
    log("Working concept coach assignments for: #{user.name}")
    student.role.taskings.preload(task: { task_steps: :tasked }).each do |tasking|
      task = tasking.task
      next unless task.concept_coach?

      task.task_steps.each{ |task_step| work_step(task_step, Random.rand < 0.5) }
    end
  end
end
