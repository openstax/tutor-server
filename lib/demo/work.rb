require_relative 'base'
require_relative 'config/course'
require_relative 'config/task_profile'

# Adds students to the course periods, assigns Sets up the periods and students for a course
# and then generates activity for them
class Demo::Work < Demo::Base
  lev_routine

  disable_automatic_lev_transactions

  protected

  def exec(config: :all, random_seed: nil)
    set_random_seed(random_seed)

    in_parallel(Demo::Config::Course[config], transaction: true) do |course_configs, initial_index|
      course_configs.each do |course_config|
        assignments = course_config.assignments.reject(&:draft) +
                      get_auto_assignments(course_config).flatten

        assignments.each { |assignment| work_tp_assignment(course_config, assignment) }
      end
    end

    wait_for_parallel_completion
  end

  def build_tasks_profile(assignment_type:, students:)
    user_responses = students.map do |username, score|
      user = user_for_username(username) ||
             raise("Unable to find student with username #{username}")

      [username, user, score]
    end

    Demo::Config::TaskProfile.new(assignment_type: assignment_type,
                                  user_responses: user_responses,
                                  randomizer: randomizer)
  end

  # Works steps with the given responses; for exercise steps, response can be
  # true/false or 1/0 or '1'/'0' to represent right or wrong.
  # For any step, a nil or 'n' means incomplete, non-nil means complete.
  def work_task(tasks_profile:, task:)
    responses = tasks_profile.explicit_responses(task: task)
    is_completed = ->(task, task_step, index) do
      response = responses[index]
      response.present? && response != 'n'
    end
    is_correct = ->(task, task_step, index) do
      response = responses[index]

      case response
      when Integer
        response.zero? ? false : true
      when String
        response == '0' ? false : true
      else
        !!response
      end
    end

    Preview::WorkTask[task: task, is_completed: is_completed, is_correct: is_correct]
  end

  def work_tp_assignment(course_config, assignment)
    course = find_demo_course_by_name!(course_config.course_name)
    task_plan = Tasks::Models::TaskPlan.order(created_at: :desc).find_by!(
                  owner: course, title: assignment.title
                )

    tasks_profile = build_tasks_profile(
      students: assignment.periods.flat_map { |period| period.students.map(&:to_a) },
      assignment_type: assignment.type.to_sym
    )

    log do
      "Working #{assignment.type} #{assignment.title} for course #{course.name} (id: #{course.id})"
    end

    task_plan.tasks
             .joins(taskings: {role: :student})
             .preload([{taskings: {role: {profile: :account}}}, {task_steps: [:tasked, :task]}])
             .each_with_index do |task, index|

      task_profile = tasks_profile[task]

      unless task_profile
        raise "#{assignment.title} period #{period.id} has no responses for task #{
              index} for user #{user.id} #{user.username}"
      end
      lateness = assignment.late ? assignment.late[task_profile.username] : nil
      worked_at = task.due_at + (lateness ? lateness : -60)

      Timecop.freeze(worked_at) do
        work_task(tasks_profile: tasks_profile, task: task)
      end
    end
  end
end
