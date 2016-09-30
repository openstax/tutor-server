class ResetPracticeWidget

  EXERCISES_COUNT = 5

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
  uses_routine GetEcosystemFromIds, as: :get_ecosystem

  protected

  def exec(role:, exercise_source:, page_ids: nil, chapter_ids: nil, randomize: true)
    course = role.student.try!(:course)

    if course.present?
      fatal_error(code: :course_not_started) unless course.started?
      fatal_error(code: :course_ended) if course.ended?
    end

    # Get the existing practice widget and hard-delete
    # incomplete exercises from it so they can be used in later practice
    existing_practice_task = run(:get_practice_widget, role: role).outputs.task
    existing_practice_task.task_steps.incomplete.each(&:really_destroy!) \
      unless existing_practice_task.nil?

    ecosystem = run(:get_ecosystem, page_ids: page_ids, chapter_ids: chapter_ids).outputs.ecosystem

    # Gather relevant chapters and pages
    chapters = ecosystem.chapters_by_ids(chapter_ids)
    pages = ecosystem.pages_by_ids(page_ids) + chapters.map(&:pages).flatten.uniq

    case exercise_source
    when :local
      exercises = get_local_exercises(ecosystem: ecosystem, pages: pages, role: role,
                                      count: EXERCISES_COUNT, randomize: randomize)
    when :biglearn
      # TODO: Send assignment topic to Biglearn properly
      task = Tasks::Models::Task.new

      OpenStax::Biglearn::Api.create_update_assignments(task: task)

      exercises = OpenStax::Biglearn::Api.fetch_assignment_pes(
        task: task, max_exercises_to_return: EXERCISES_COUNT
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

    # Figure out the type of practice
    task_type = :mixed_practice
    task_type = :chapter_practice if chapter_ids.present? && page_ids.blank?
    task_type = :page_practice if chapter_ids.blank? && page_ids.present?

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
