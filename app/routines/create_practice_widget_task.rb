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

  def exec(role:, mode: nil, page_ids: nil, chapter_ids: nil, randomize: true)
    student = role.student
    course = student.course
    fatal_error(code: :course_has_no_ecosystems) if course.ecosystems.empty?

    if page_ids.present? || chapter_ids.present?
      ecosystem = run(
        :get_ecosystem, page_ids: page_ids, chapter_ids: chapter_ids
      ).outputs.ecosystem
      course_ecosystems = course.ecosystems.map { |eco| Content::Ecosystem.new strategy: eco.wrap }
      fatal_error(code: :invalid_page_ids_or_chapter_ids) \
        unless course_ecosystems.include?(ecosystem)

      # Gather relevant chapters and pages
      chapters = ecosystem.chapters_by_ids(chapter_ids)
      pages = ecosystem.pages_by_ids(page_ids) + chapters.map(&:pages).flatten.uniq
    else
      mode ||= 'most_needed'

      ecosystem = Content::Ecosystem.new strategy: course.ecosystems.first.wrap

      pages = []
    end

    # Figure out the type of practice
    task_type = if chapter_ids.present?
      page_ids.present? ? :mixed_practice : :chapter_practice
    else
      :page_practice
    end

    time_zone = course.time_zone

    # Create the new practice widget task
    run(
      :build_task,
      task_type: task_type,
      time_zone: time_zone,
      title: 'Practice',
      ecosystem: ecosystem.to_model
    )

    run(:add_spy_info, to: outputs.task, from: ecosystem)

    run(:create_tasking, role: role, task: outputs.task)

    outputs.task.save!

    # NOTE: These calls lock the course from further Biglearn interaction until
    # the end of the transaction, so hopefully the rest of routine finishes pretty fast...
    case mode
    when 'most_needed'
      exercises = OpenStax::Biglearn::Api.fetch_practice_worst_areas_exercises(
        student: student, max_num_exercises: EXERCISES_COUNT
      )
    else
      OpenStax::Biglearn::Api.create_update_assignments(
        course: course, task: outputs.task, core_page_ids: pages.map(&:id), perform_later: false
      )
      exercises = OpenStax::Biglearn::Api.fetch_assignment_pes(
        task: outputs.task, max_num_exercises: EXERCISES_COUNT
      )
    end

    fatal_error(
      code: :no_exercises,
      message: "No exercises were found to build the Practice Widget." +
               " [mode: #{mode} - pages: #{pages.map(&:uuid).inspect} - role: #{role.id}" +
               " - requested: #{EXERCISES_COUNT} - got: 0]"
    ) if exercises.size == 0

    # Create the new practice widget task, and put the exercises into steps
    exercises.each do |exercise|
      TaskExercise.call(exercise: exercise, task: outputs.task) do |step|
        step.group_type = :personalized_group
        step.add_related_content(exercise.page.related_content)
      end
    end

    OpenStax::Biglearn::Api.create_update_assignments(course: course, task: outputs.task)
  end

end
