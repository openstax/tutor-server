module CreatePracticeTaskRoutine
  extend ActiveSupport::Concern

  EXERCISES_COUNT = 5

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

  def exec(course:, role:, **args)
    fatal_error(code: :course_not_started) unless course.started?
    fatal_error(code: :course_ended) if course.ended?
    fatal_error(code: :course_has_no_ecosystems) if course.ecosystems.empty?

    # Get the existing practice widget and hard-delete
    # incomplete exercises from it so they can be used in later practice
    existing_practice_task = run(:get_practice_task, role: role).outputs.task
    existing_practice_task.task_steps.incomplete.each(&:really_destroy!) \
      unless existing_practice_task.nil?

    # This method must setup @task_type and @ecosystem,
    # as well as any other variables needed for the get_exercises method
    setup(course: course, role: role, **args)
    raise 'Invalid @task_type' unless Tasks::Models::Task.task_types.keys.include?(@task_type.to_s)
    raise '@ecosystem cannot be blank' if @ecosystem.blank?

    time_zone = course.time_zone

    # Create the new practice widget task
    task = run(
      :build_task,
      task_type: @task_type,
      time_zone: time_zone,
      title: 'Practice',
      ecosystem: @ecosystem.to_model
    ).outputs.task

    run(:add_spy_info, to: task, from: @ecosystem)

    run(:create_tasking, role: role, task: task)

    task.save!

    # NOTE: Biglearn calls here lock the course from further Biglearn interaction until
    # the end of the transaction, so hopefully the rest of routine finishes pretty fast...
    exercises = get_exercises(task: task, count: EXERCISES_COUNT)

    fatal_error(
      code: :no_exercises,
      message: "No exercises were found to build the Practice Widget." +
               " [Course: #{course.id} - Role: #{role.id} - Args: #{args.inspect}" +
               " - Requested: #{EXERCISES_COUNT} - Got: 0]"
    ) if exercises.size == 0

    # Add the exercises as task steps
    exercises.each do |exercise|
      TaskExercise.call(exercise: exercise, task: task) do |step|
        step.group_type = :personalized_group
        step.add_related_content(exercise.page.related_content)
      end
    end

    OpenStax::Biglearn::Api.create_update_assignments(course: course, task: task)
  end

end
