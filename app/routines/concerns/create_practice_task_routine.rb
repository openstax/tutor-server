module CreatePracticeTaskRoutine

  NUM_BIGLEARN_EXERCISES = 5

  extend ActiveSupport::Concern

  included do
    lev_routine express_output: :task

    uses_routine Tasks::GetPracticeTask, as: :get_practice_task
    uses_routine Tasks::BuildTask,
      translations: { outputs: { type: :verbatim } },
      as: :build_task

    uses_routine AddSpyInfo, as: :add_spy_info

    uses_routine Tasks::CreateTasking,
      translations: { outputs: { type: :verbatim } },
      as: :create_tasking
  end

  protected

  def add_task_steps
  end

  def send_task_to_biglearn
    OpenStax::Biglearn::Api.create_update_assignments(
      course: @course,
      task: @task,
      goal_num_tutor_assigned_pes: NUM_BIGLEARN_EXERCISES
    )
  end

  def exec(course:, role:, **args)
    fatal_error(code: :course_not_started) unless course.started?
    fatal_error(code: :course_ended) if course.ended?
    fatal_error(code: :course_has_no_ecosystems) if course.ecosystems.empty?

    # Get the existing practice widget and hard-delete
    # incomplete exercises from it so they can be used in later practice
    existing_practice_task = run(:get_practice_task, role: role).outputs.task
    existing_practice_task.task_steps.incomplete.each(&:really_destroy!) \
      unless existing_practice_task.nil?

    @course = course
    @role = role

    # This method must setup @task_type and @ecosystem,
    # as well as any other variables needed for the get_exercises method
    setup(**args)
    raise 'Invalid @task_type' unless Tasks::Models::Task.task_types.keys.include?(@task_type.to_s)
    raise '@ecosystem cannot be blank' if @ecosystem.blank?

    time_zone = course.time_zone

    # Create the new practice widget task
    @task = run(
      :build_task,
      task_type: @task_type,
      time_zone: time_zone,
      title: 'Practice',
      ecosystem: @ecosystem.to_model
    ).outputs.task

    run(:add_spy_info, to: @task, from: @ecosystem)

    run(:create_tasking, role: role, task: @task)

    @task.save!

    add_task_steps

    send_task_to_biglearn
  end

end
