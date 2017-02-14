class CreatePracticeWidgetTask

  EXERCISES_COUNT = 5

  lev_routine express_output: :task

  uses_routine Tasks::BuildTask,
    translations: { outputs: { type: :verbatim } },
    as: :build_task

  uses_routine AddSpyInfo, as: :add_spy_info

  uses_routine Tasks::CreateTasking,
    translations: { outputs: { type: :verbatim } },
    as: :create_tasking

  uses_routine GetHistory, as: :get_history
  uses_routine FilterExcludedExercises, as: :filter
  uses_routine ChooseExercises, as: :choose
  uses_routine GetEcosystemFromIds, as: :get_ecosystem

  protected

  def exec(role:, exercise_source:, page_ids: nil, chapter_ids: nil, randomize: true)
    ecosystem = run(:get_ecosystem, page_ids: page_ids, chapter_ids: chapter_ids).outputs.ecosystem
    course = role.student.course
    time_zone = course.time_zone

    # Gather relevant chapters and pages
    chapters = ecosystem.chapters_by_ids(chapter_ids)
    pages = ecosystem.pages_by_ids(page_ids) + chapters.map(&:pages).flatten.uniq

    # Figure out the type of practice
    task_type = :mixed_practice
    task_type = :chapter_practice if chapter_ids.present? && page_ids.blank?
    task_type = :page_practice if chapter_ids.blank? && page_ids.present?

    # Create the new practice widget task
    run(
      :build_task,
      task_type: task_type,
      time_zone: time_zone,
      title: 'Practice',
      ecosystem: ecosystem.to_model
    )

    case exercise_source
    when :local
      exercises = get_local_exercises(ecosystem: ecosystem, pages: pages, role: role,
                                      count: EXERCISES_COUNT, randomize: randomize)
    when :biglearn
      # NOTE: This call right here locks the course from further Biglearn interaction until
      # the end of the transaction, so hopefully the rest of routine finishes pretty fast...
      OpenStax::Biglearn::Api.create_update_assignments(
        course: course, task: outputs.task, core_page_ids: pages.map(&:id), perform_later: false
      )
      exercises = OpenStax::Biglearn::Api.fetch_assignment_pes(
        task: outputs.task, max_exercises_to_return: EXERCISES_COUNT
      )
    else
      raise ArgumentError, "exercise_source: must be one of [:local, :biglearn]"
    end

    num_exercises = exercises.size

    # If Biglearn returns less exercises than requested, complete the count with local ones
    if num_exercises < EXERCISES_COUNT && exercise_source == :biglearn
      biglearn_numbers = exercises.map(&:number)
      local_exercises = get_local_exercises(ecosystem: ecosystem, pages: pages, role: role,
                                            count: EXERCISES_COUNT - num_exercises,
                                            randomize: randomize,
                                            additional_excluded_numbers: biglearn_numbers)
      exercises += local_exercises
    end

    fatal_error(
      code: :no_exercises,
      message: "No exercises were found to build the Practice Widget. [" +
               "pages: #{pages.map(&:uuid).inspect}, role: #{role.id}, " +
               "needed: #{EXERCISES_COUNT}, got: 0]"
    ) if exercises.size == 0

    # Create the new practice widget task, and put the exercises into steps
    exercises.each do |exercise|
      TaskExercise.call(exercise: exercise, task: outputs.task) do |step|
        step.group_type = :personalized_group
        step.add_related_content(exercise.page.related_content)
      end
    end

    run(:add_spy_info, to: outputs.task, from: ecosystem)

    run(:create_tasking, role: role, task: outputs.task)

    outputs.task.save!

    OpenStax::Biglearn::Api.create_update_assignments(course: course, task: outputs.task)
  end

  def get_local_exercises(ecosystem:, pages:, role:, count:,
                          randomize:, additional_excluded_numbers: [])
    # Gather exercises from the relevant pools
    pool_exercises = ecosystem.practice_widget_pools(pages: pages).flat_map(&:exercises)
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
