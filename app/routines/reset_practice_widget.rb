class ResetPracticeWidget
  lev_routine outputs: { entity_task: :_self },
              uses: [{ name: Tasks::CreateTasking, as: :create_tasking },
                     { name: Tasks::CreatePracticeWidgetTask, as: :create_practice_widget_task },
                     GetPracticeWidget,
                     AddSpyInfo,
                     GetCourseEcosystem,
                     GetHistory,
                     GetEcosystemExercisesFromBiglearn]

  protected

  def exec(role:, exercise_source:, page_ids: nil, chapter_ids: nil, randomize: true)
    # Get the existing practice widget and remove incomplete exercises from it
    # so they can be used in later practice
    existing_practice_task = run(:get_practice_widget, role: role).task.try(:task)
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
                  .ecosystem_exercises
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
     task = run(:create_practice_widget_task, exercises: exercises,
                                              task_type: task_type,
                                              related_content_array: related_content_array).task
    run(:add_spy_info, to: task, from: ecosystem)

    run(:create_tasking, role: role, task: task.entity_task)

    set(entity_task: task.entity_task)
  end

  def get_fake_exercises(count)
    count.times.collect do
      content_exercise = FactoryGirl.create(:content_exercise)
      strategy = ::Content::Strategies::Direct::Exercise.new(content_exercise)
      ::Content::Exercise.new(strategy: strategy)
    end
  end

  def get_ecosystem_and_pools(page_ids, chapter_ids, role)
    ecosystem = GetEcosystemFromIds.call(page_ids: page_ids, chapter_ids: chapter_ids).ecosystem

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
    all_worked_exercises = run(:get_history, role: role, type: :all).exercises.flatten.uniq
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
