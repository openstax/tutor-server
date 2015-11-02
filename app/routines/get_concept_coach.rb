class GetConceptCoach

  CORE_EXERCISES_COUNT = 4
  SPACED_EXERCISES_COUNT = 3

  lev_routine express_output: :entity_task

  uses_routine Tasks::GetConceptCoachTask, as: :get_cc_task

  uses_routine Tasks::CreateConceptCoachTask,
    translations: { outputs: { type: :verbatim } },
    as: :create_cc_task

  uses_routine Tasks::CreateTasking,
    translations: { outputs: { type: :verbatim } },
    as: :create_tasking

  uses_routine AddSpyInfo, as: :add_spy_info

  uses_routine GetCourseEcosystem, as: :get_course_ecosystem
  uses_routine GetHistory, as: :get_history

  protected

  def exec(role:, page:)
    existing_cc_task = run(:get_cc_task, role: role, page: page).outputs.entity_task
    unless existing_cc_task.nil?
      outputs.entity_task = existing_cc_task
      return
    end

    ecosystem, pool = get_ecosystem_and_pool(page)
    history = run(:get_history, role: role, type: :concept_coach).outputs
    all_worked_exercises = history.exercises
    all_worked_exercise_numbers = all_worked_exercises.map(&:number)
    core_exercises = get_local_exercises(CORE_EXERCISES_COUNT, pool, history.exercises)

    current_exercise_numbers = core_exercises.map(&:number)
    ecosystems_map = {}

    spaced_tasks = history.tasks.slice(1..-1) || []

    spaced_exercises = spaced_tasks.empty? ? [] : SPACED_EXERCISES_COUNT.times.collect do
      spaced_task = spaced_tasks.sample
      spaced_page_model = task.concept_coach_task.page
      spaced_page = Content::Page.new(strategy: spaced_page_model.wrap)
      spaced_ecosystem, spaced_page = get_ecosystem_and_pool(spaced_page)
      ecosystems_map[spaced_ecosystem.id] ||= Content::Map.find(
        from_ecosystems: [spaced_ecosystem, ecosystem].uniq, to_ecosystem: ecosystem
      )

      # Map the spaced page to exercises in the current ecosystem
      spaced_exercises = ecosystems_map[spaced_ecosystem.id].map_pages_to_exercises(
        pages: spaced_pages, pool_type: :all_exercises
      )

      # Exclude exercises already worked (by number)
      candidate_exercises = spaced_exercises.values.flatten.uniq.reject do |ex|
        all_worked_exercise_numbers.include?(ex.number)
      end

      # Randomize and grab one exercise
      chosen_exercise = candidate_exercises.shuffle.first

      if chosen._exercise.nil?
        # Try again allowing repeats (but not from the current task)
        candidate_exercises = spaced_exercises.values.flatten.uniq.reject do |ex|
          current_exercise_numbers.include?(ex.number)
        end

        chosen_exercise = candidate_exercises.shuffle.first

        next if chosen_exercise.nil?
      end

      all_worked_exercise_numbers << chosen_exercise.number
      current_exercise_numbers << chosen_exercise.number

      chosen_exercise
    end.compact

    exercises = core_exercises + spaced_exercises

    related_content_array = exercises.collect{ |ex| ex.page.related_content }

    # Create the new concept coach task, and put the exercises into steps
    run(:create_cc_task, page: page, exercises: exercises,
                         related_content_array: related_content_array)

    run(:add_spy_info, to: outputs.task, from: ecosystem)

    run(:create_tasking, role: role, task: outputs.task.entity_task)

    outputs.entity_task = outputs.task.entity_task
  end

  def get_ecosystem_and_pool(page)
    ecosystem = Content::Ecosystem.find_by_page_ids(page.id)
    [ecosystem, page.all_exercises_pool]
  end

  def get_local_exercises(count, pool, exercise_history)
    all_worked_exercises = exercise_history.flatten.uniq
    exercise_pool = pool.exercises.uniq.shuffle
    candidate_exercises = exercise_pool - all_worked_exercises
    candidate_exercises.first(count)
  end

end
