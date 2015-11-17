class GetConceptCoach

  lev_routine express_output: :entity_task

  uses_routine Tasks::GetConceptCoachTask, as: :get_cc_task

  uses_routine Tasks::CreateConceptCoachTask,
    translations: { outputs: { type: :verbatim } },
    as: :create_cc_task

  uses_routine Tasks::CreateTasking,
    translations: { outputs: { type: :verbatim } },
    as: :create_tasking

  uses_routine AddSpyInfo, as: :add_spy_info

  uses_routine GetHistory, as: :get_history

  uses_routine GetCourseEcosystem, as: :get_ecosystem

  protected

  def exec(user:, cnx_book_id:, cnx_page_id:)
    role, page = get_role_and_page(user: user, cnx_book_id: cnx_book_id, cnx_page_id: cnx_page_id)

    existing_cc_task = run(:get_cc_task, role: role, page: page).outputs.entity_task
    unless existing_cc_task.nil?
      outputs.entity_task = existing_cc_task
      outputs.task = existing_cc_task.task
      return
    end

    ecosystem, pool = get_ecosystem_and_pool(page)
    history = run(:get_history, role: role, type: :concept_coach).outputs
    all_worked_exercises = history.exercises.flatten
    all_worked_exercise_numbers = all_worked_exercises.map(&:number)
    core_exercises = get_local_exercises(
      Tasks::Models::ConceptCoachTask::CORE_EXERCISES_COUNT, pool, all_worked_exercises
    )

    current_exercise_numbers = core_exercises.map(&:number)
    ecosystems_map = {}

    spaced_tasks = history.tasks || []

    spaced_exercises = spaced_tasks.empty? ? \
      [] : Tasks::Models::ConceptCoachTask::SPACED_EXERCISES_COUNT.times.collect do
      spaced_task = spaced_tasks.sample
      spaced_page_model = spaced_task.concept_coach_task.page
      spaced_page = Content::Page.new(strategy: spaced_page_model.wrap)
      spaced_ecosystem = Content::Ecosystem.find_by_page_ids(spaced_page.id)
      ecosystems_map[spaced_ecosystem.id] ||= Content::Map.find(
        from_ecosystems: [spaced_ecosystem, ecosystem].uniq, to_ecosystem: ecosystem
      )

      # Map the spaced page to exercises in the current ecosystem
      spaced_exercises = ecosystems_map[spaced_ecosystem.id].map_pages_to_exercises(
        pages: spaced_page, pool_type: :all_exercises
      )

      # Exclude exercises already worked (by number)
      candidate_exercises = spaced_exercises.values.flatten.uniq.reject do |ex|
        all_worked_exercise_numbers.include?(ex.number)
      end

      # Randomize and grab one exercise
      chosen_exercise = candidate_exercises.shuffle.first

      if chosen_exercise.nil?
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

    run(:add_spy_info, to: outputs.task, from: [ecosystem, history.tasks])

    run(:create_tasking, role: role, task: outputs.task.entity_task, period: role.student.period)

    outputs.entity_task = outputs.task.entity_task
  end

  def get_role_and_page(user:, cnx_book_id:, cnx_page_id:)
    roles = Role::GetUserRoles[user, :student]
    ecosystem_id_role_map = roles.each_with_object({}) do |role, hash|
      course = role.student.course
      next unless course.is_concept_coach

      ecosystem_id = run(:get_ecosystem, course: course).outputs.ecosystem.id
      hash[ecosystem_id] ||= []
      hash[ecosystem_id] << role
    end

    page_models = Content::Models::Page
      .joins(:book)
      .where(book: { uuid: cnx_book_id, content_ecosystem_id: ecosystem_id_role_map.keys },
             uuid: cnx_page_id)

    # If page_models.size > 1, the user is in 2 courses with the same CC book (not allowed)
    page_model = page_models.order(:created_at).last

    if page_model.blank?
      valid_books = Content::Models::Book.where(content_ecosystem_id: ecosystem_id_role_map.keys)
                                         .to_a
      valid_book_with_cnx_book_id = valid_books.select{ |book| book.uuid == cnx_book_id }.first

      if !valid_book_with_cnx_book_id.nil?
        # Book is valid for the user, but page is invalid
        outputs.valid_book_urls = [valid_book_with_cnx_book_id].map(&:url)
        fatal_error(code: :invalid_page)
      elsif !valid_books.empty?
        # Book is invalid for the user, but there are other valid books
        outputs.valid_book_urls = valid_books.map(&:url)
        fatal_error(code: :invalid_book)
      else
        # Not a CC student
        outputs.valid_book_urls = []
        fatal_error(code: :not_a_cc_student)
      end

      return [nil, nil]
    end

    ecosystem_id = page_model.book.content_ecosystem_id
    roles = ecosystem_id_role_map[ecosystem_id]
    # If roles.size > 1, the user is in 2 courses with the same CC book (not allowed)
    # We are guaranteed to have at least one role here, since we already filtered the page above
    role = roles.first

    page = Content::Page.new(strategy: page_model.wrap)

    [role, page]
  end

  def get_ecosystem_and_pool(page)
    ecosystem = Content::Ecosystem.find_by_page_ids(page.id)
    [ecosystem, page.all_exercises_pool]
  end

  def get_local_exercises(count, pool, all_worked_exercises)
    exercise_pool = pool.exercises.uniq.shuffle
    candidate_exercises = exercise_pool - all_worked_exercises
    candidate_exercises.first(count)
  end

end
