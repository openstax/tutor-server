class ResetPracticeWidget
  lev_routine express_output: :task

  uses_routine GetPracticeWidget, as: :get_practice_widget

  uses_routine AddSpyInfo, as: :add_spy_info

  uses_routine Tasks::CreateTasking,
    translations: { outputs: { type: :verbatim } },
    as: :create_tasking

  uses_routine Tasks::CreatePracticeWidgetTask,
    translations: { outputs: { type: :verbatim } },
    as: :create_practice_widget_task

  uses_routine GetHistory, as: :get_history
  uses_routine FilterExcludedExercises, as: :filter
  uses_routine ChooseExercises, as: :choose
  uses_routine GetEcosystemExercisesFromBiglearn, as: :get_ecosystem_exercises_from_biglearn

  protected

  def exec(role:, exercise_source:, page_ids: nil, chapter_ids: nil, randomize: true)
    # Get the existing practice widget and hard-delete
    # incomplete exercises from it so they can be used in later practice
    existing_practice_task = run(:get_practice_widget, role: role).outputs.task
    existing_practice_task.task_steps.incomplete.each(&:really_destroy!) \
      unless existing_practice_task.nil?

    # Gather 5 exercises
    count = 5

    case exercise_source
    when :fake
      pools = []
      exercises = get_fake_exercises(count)
      ecosystem = Content::Ecosystem.find_by_exercise_ids(exercises.first.id) if exercises.any?
    when :local
      ecosystem, pools = get_ecosystem_and_pools(page_ids, chapter_ids, role)
      exercises = get_local_exercises(ecosystem: ecosystem, count: count,
                                      role: role, pools: pools, randomize: randomize)
    when :biglearn
      ecosystem, pools = get_ecosystem_and_pools(page_ids, chapter_ids, role)
      out = run(:get_ecosystem_exercises_from_biglearn, ecosystem: ecosystem,
                                                        count: count,
                                                        role: role,
                                                        pools: pools).outputs
      exercises = out.ecosystem_exercises
      biglearn_numbers = out.exercise_numbers
    else
      raise ArgumentError, "exercise_source: must be one of [:fake, :local, :biglearn]"
    end

    num_exercises = exercises.size

    # If Biglearn returns less exercises than requested, complete the count with local ones
    if num_exercises < count && exercise_source == :biglearn
      local_exercises = get_local_exercises(ecosystem: ecosystem, count: count - num_exercises,
                                            role: role, pools: pools, randomize: randomize,
                                            additional_excluded_numbers: biglearn_numbers)
      exercises += local_exercises
    end

    fatal_error(
      code: :no_exercises,
      message: "No exercises were found to build the Practice Widget. [pools: #{pools.inspect}, " +
               "role: #{role.id}, needed: #{count}, got: 0]"
    ) if exercises.size == 0

    # Figure out the type of practice
    task_type = :mixed_practice
    task_type = :chapter_practice if !chapter_ids.nil? && page_ids.nil?
    task_type = :page_practice if chapter_ids.nil? && !page_ids.nil?

    related_content_array = exercises.map{ |ex| ex.page.related_content }

    # Create the new practice widget task, and put the exercises into steps
    time_zone = role.student.try(:course).try(:time_zone)
    run(:create_practice_widget_task, exercises: exercises,
                                      task_type: task_type,
                                      related_content_array: related_content_array,
                                      time_zone: time_zone)
    run(:add_spy_info, to: outputs.task, from: ecosystem)

    run(:create_tasking, role: role, task: outputs.task)
  end

  def get_fake_exercises(count)
    count.times.map do
      content_exercise = FactoryGirl.create(:content_exercise)
      strategy = ::Content::Strategies::Direct::Exercise.new(content_exercise)
      ::Content::Exercise.new(strategy: strategy)
    end
  end

  def get_ecosystem_and_pools(page_ids, chapter_ids, role)
    ecosystem = GetEcosystemFromIds[page_ids: page_ids, chapter_ids: chapter_ids]

    # Gather relevant chapters and pages
    chapters = ecosystem.chapters_by_ids(chapter_ids)
    pages = ecosystem.pages_by_ids(page_ids) + chapters.map(&:pages).flatten.uniq

    # Gather exercise pools
    [ecosystem, ecosystem.practice_widget_pools(pages: pages)]
  end

  def get_local_exercises(ecosystem:, count:, role:, pools:, randomize:,
                          additional_excluded_numbers: [])
    pool_exercises = pools.flat_map(&:exercises)

    course = role.student.try(:course)
    filtered_exercises = run(
      :filter, exercises: pool_exercises, course: course,
               additional_excluded_numbers: additional_excluded_numbers
    ).outputs.exercises

    history = run(:get_history, roles: role, type: :all).outputs.history[role]
    chosen_exercises = run(:choose, exercises: filtered_exercises, count: count, history: history,
                                    allow_repeats: false,
                                    randomize_exercises: randomize,
                                    randomize_order: randomize).outputs.exercises
    chosen_exercises
  end

end
