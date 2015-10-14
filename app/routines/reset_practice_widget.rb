class ResetPracticeWidget
  lev_routine express_output: :entity_task

  uses_routine GetPracticeWidget, as: :get_practice_widget

  uses_routine AddSpyInfo, as: :add_spy_info

  uses_routine Tasks::CreateTasking,
    translations: { outputs: { type: :verbatim } },
    as: :create_tasking

  uses_routine Tasks::CreatePracticeWidgetTask,
    translations: { outputs: { type: :verbatim } },
    as: :create_practice_widget_task

  uses_routine GetCourseEcosystem, as: :get_course_ecosystem
  uses_routine GetHistory, as: :get_history
  uses_routine GetEcosystemExercisesFromBiglearn, as: :get_ecosystem_exercises_from_biglearn

  protected

  def exec(role:, exercise_source:, page_ids: nil, chapter_ids: nil, randomize: true)
    # Get the existing practice widget and remove incomplete exercises from it
    # so they can be used in later practice
    existing_practice_task = run(:get_practice_widget, role: role).outputs.task.try(:task)
    existing_practice_task.task_steps.incomplete.destroy_all unless existing_practice_task.nil?

    # Gather 5 exercises
    count = 5

    case exercise_source
    when :fake
      pools = []
      exercises = get_fake_exercises(count)
      ecosystem = Content::Ecosystem.find_by_exercise_ids(exercises.first.id) if exercises.any?
    when :local
      ecosystem, pools = get_ecosystem_and_pools(page_ids, chapter_ids, role)
      exercises = get_local_exercises(ecosystem, count, role, pools, randomize: randomize)
    when :biglearn
      ecosystem, pools = get_ecosystem_and_pools(page_ids, chapter_ids, role)
      exercises = run(:get_ecosystem_exercises_from_biglearn, ecosystem: ecosystem,
                      count: count,
                      role: role,
                      pools: pools)
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
        message: "Not enough exercises to build the Practice Widget. [pools: #{pools.inspect}, " +
                 "role: #{role.id}, needed: #{count}, got: #{num_exercises}]"
      )
    end

    # Figure out the type of practice
    task_type = :mixed_practice
    task_type = :chapter_practice if !chapter_ids.nil? && page_ids.nil?
    task_type = :page_practice if chapter_ids.nil? && !page_ids.nil?

    related_content_array = exercises.collect{ |ex| ex.page.related_content }

    # Create the new practice widget task, and put the exercises into steps
    run(:create_practice_widget_task, exercises: exercises,
                                      task_type: task_type,
                                      related_content_array: related_content_array)
    run(:add_spy_info, to: outputs.task, from: ecosystem)

    run(:create_tasking, role: role, task: outputs.task.entity_task)

    outputs.entity_task = outputs.task.entity_task
  end

  def get_fake_exercises(count)
    count.times.collect do
      content_exercise = FactoryGirl.create(:content_exercise)
      strategy = ::Content::Strategies::Direct::Exercise.new(content_exercise)
      ::Content::Exercise.new(strategy: strategy)
    end
  end

  def get_ecosystem_and_pools(page_ids, chapter_ids, role)
    ecosystem = GetEcosystemFromIds[page_ids: page_ids, chapter_ids: chapter_ids]

    # Gather relevant chapters and pages
    chapters = ecosystem.chapters_by_ids(chapter_ids)
    pages = ecosystem.pages_by_ids(page_ids) + chapters.collect{ |ch| ch.pages }.flatten.uniq

    # Gather exercise pools
    [ecosystem, ecosystem.practice_widget_pools(pages: pages)]
  end

  def get_local_exercises(ecosystem, count, role, pools, options = {})
    options = { randomize: true }.merge(options)
    entity_tasks = role.taskings.preload(task: {task: {task_steps: :tasked}})
                                .collect{ |tt| tt.task }
    all_worked_exercises = run(:get_history, role: role, type: :all).outputs.exercises.flatten.uniq
    exercise_pool = pools.collect{ |pl| pl.exercises }.flatten.uniq
    exercise_pool = exercise_pool.shuffle if options[:randomize]
    candidate_exercises = (exercise_pool - all_worked_exercises)
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
