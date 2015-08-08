class ResetPracticeWidget
  lev_routine express_output: :task

  uses_routine GetPracticeWidget, as: :get_practice_widget

  uses_routine Tasks::CreateTasking,
    translations: { outputs: { type: :verbatim } },
    as: :create_tasking

  uses_routine Tasks::CreatePracticeWidgetTask,
    translations: { outputs: { type: :verbatim } },
    as: :create_practice_widget_task

  uses_routine GetCourseEcosystem, as: :get_course_ecosystem
  uses_routine GetTasksExerciseHistory, as: :get_tasks_exercise_history
  uses_routine GetEcosystemExercisesFromBiglearn, as: :get_ecosystem_exercises_from_biglearn

  protected

  def exec(role:, exercise_source:, page_ids: [], chapter_ids: [], randomize: true)
    page_ids = [page_ids].flatten.compact
    book_part_ids = [book_part_ids].flatten.compact

    # Get the existing practice widget and remove incomplete exercises from it
    # so they can be used in later practice
    existing_practice_task = run(:get_practice_widget, role: role).outputs.task.try(:task)
    existing_practice_task.task_steps.incomplete.destroy_all unless existing_practice_task.nil?

    # Gather 5 exercises
    count = 5
    exercises = case exercise_source
                when :fake
                  get_fake_exercises(count)
                when :local
                  get_local_exercises(count, role, get_pools(role), randomize: randomize)
                when :biglearn
                  run(:get_ecosystem_exercises_from_biglearn, count: count,
                                                              role: role,
                                                              pools: get_pools(role))
                    .outputs.ecosystem_exercises
                else
                  raise ArgumentError,
                        "exercise_source: must be one of [:fake, :local, :biglearn]"
                end

    num_exercises = exercises.size

    if num_exercises < count
      # Not enough exercises
      fatal_error(
        code: :not_enough_exercises,
        message: "Not enough exercises to build the Practice Widget. [los: #{los.inspect}, " +
                 "role: #{role.id}, needed: #{count}, got: #{num_exercises}]"
      )
    end

    # Figure out the type of practice
    task_type = :mixed_practice
    task_type = :chapter_practice if book_part_ids.count > 0 && page_ids.count == 0
    task_type = :page_practice if book_part_ids.count == 0 && page_ids.count > 0

    related_content_array = exercises.collect{ |ex| ex.page.related_content }

    # Create the new practice widget task, and put the exercises into steps
    run(:create_practice_widget_task, exercises: exercises,
                                      task_type: task_type,
                                      related_content_array: related_content_array)

    run(:create_tasking, role: role, task: outputs.task.entity_task)

    outputs.task = outputs.task.entity_task
  end

  def get_fake_exercises(count)
    count.times.collect do
      content_exercise = FactoryGirl.build(:content_exercise)
      strategy = ::Ecosystem::Strategies::Direct::Exercise.new(content_exercise)
      ::Ecosystem::Exercise.new(strategy: strategy)
    end
  end

  def get_pools(role)
    # We can only handle student roles for now
    ecosystem = run(:get_course_ecosystem, course: role.student.course).outputs.ecosystem

    # Gather relevant chapters and pages
    chapters = ecosystem.chapters_by_ids(chapter_ids)
    pages = ecosystem.pages_by_ids(page_ids) + chapters.collect{ |ch| ch.pages }.flatten.uniq

    # Gather exercise pools
    ecosystem.practice_widget_pools(pages: pages)
  end

  def get_local_exercises(ecosystem, count, role, pools, options = {})
    options = { randomize: true }.merge(options)
    tasks = role.taskings.collect{ |tt| tt.task }
    flat_history = run(:get_tasks_exercise_history, ecosystem: ecosystem, tasks: tasks)
                     .outputs.exercise_history.flatten
    exercise_pool = pools.collect{ |pl| pl.exercises }.flatten.uniq
    exercise_pool = exercise_pool.shuffle if options[:randomize]
    candidate_exercises = (exercise_pool - flat_history)
    exercises = candidate_exercises.first(count)
    num_exercises = exercises.size

    if num_exercises < count
      # We ran out of exercises, so start repeating them
      candidate_exercises = exercise_pool - exercises
      exercises = exercises + candidate_exercises.first(count - num_exercises)
    end

    exercises
  end

end
