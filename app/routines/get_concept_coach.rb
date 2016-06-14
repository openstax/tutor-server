class GetConceptCoach

  lev_routine express_output: :task, transaction: :serializable

  uses_routine Tasks::GetConceptCoachTask, as: :get_cc_task

  uses_routine Tasks::CreateConceptCoachTask,
    translations: { outputs: { type: :verbatim } },
    as: :create_cc_task

  uses_routine AddSpyInfo, as: :add_spy_info

  uses_routine GetHistory, as: :get_history

  uses_routine FilterExcludedExercises, as: :filter

  uses_routine ChooseExercises, as: :choose

  uses_routine GetCourseEcosystem, as: :get_ecosystem

  protected

  def exec(user:, cnx_book_id:, cnx_page_id:)
    role, page = get_role_and_page(user: user, cnx_book_id: cnx_book_id, cnx_page_id: cnx_page_id)

    ecosystem, pool = get_ecosystem_and_pool(page)
    history = run(:get_history, role: role, type: :concept_coach).outputs
    existing_cc_task = run(:get_cc_task, role: role, page: page).outputs.task
    unless existing_cc_task.nil?
      outputs.task = existing_cc_task
      run(:add_spy_info, to: outputs.task, from: [ecosystem, {history: history.tasks}])
      return
    end

    pool_exercises = pool.exercises.uniq
    course = role.student.try(:course)
    filtered_exercises = run(:filter, exercises: pool_exercises, course: course)
                           .outputs.exercises
    core_exercises = run(:choose, exercises: filtered_exercises,
                                  count: Tasks::Models::ConceptCoachTask::CORE_EXERCISES_COUNT,
                                  history: history, allow_repeats: false).outputs.exercises

    if core_exercises.empty?
      outputs.valid_book_urls = ecosystem.books.map(&:url)
      fatal_error(code: :page_has_no_exercises)
    end

    core_exercise_numbers = core_exercises.map(&:number)
    ecosystems_map = {}

    spaced_tasks = history.tasks || []

    spaced_practice_status = []

    # Prepare eligible random-ago tasks, but only if we have 4 or more tasks
    if spaced_tasks.size >= 4
      random_tasks = spaced_tasks.dup
      forbidden_random_ks = Tasks::Models::ConceptCoachTask::SPACED_EXERCISES_MAP
                              .map(&:first).select{ |k_ago| k_ago != :random }.uniq
      forbidden_random_ks.sort.reverse.each do |forbidden_random_k|
        # Subtract 1 from k_ago because this history does not include the current task (0-ago)
        random_tasks.delete_at(forbidden_random_k - 1)
      end
    end

    k_ago_map = Tasks::Models::ConceptCoachTask::SPACED_EXERCISES_MAP
    spaced_exercises = k_ago_map.flat_map do |k_ago, num_requested|
      # Do not do random-ago if less than 4 past tasks in history
      if k_ago == :random && spaced_tasks.size < 4
        spaced_practice_status << "Random-ago slot skipped because < 4 tasks in past history"
        next
      end

      # Select a task
      spaced_task = k_ago == :random ? random_tasks.sample : spaced_tasks[k_ago - 1]

      # Skip if no k_ago task
      if spaced_task.nil?
        spaced_practice_status << "Not enough tasks in history to fill the #{k_ago}-ago slot"
        next
      end

      spaced_page_model = spaced_task.concept_coach_task.page
      spaced_page = Content::Page.new(strategy: spaced_page_model.wrap)
      spaced_ecosystem = Content::Ecosystem.find_by_page_ids(spaced_page.id)
      ecosystems_map[spaced_ecosystem.id] ||= Content::Map.find_or_create_by(
        from_ecosystems: [spaced_ecosystem, ecosystem].uniq, to_ecosystem: ecosystem
      )

      # Map the spaced page to exercises in the current task's ecosystem
      spaced_exercises = ecosystems_map[spaced_ecosystem.id].map_pages_to_exercises(
        pages: spaced_page, pool_type: :all_exercises
      ).values.flatten.uniq

      filtered_exercises = run(:filter, exercises: spaced_exercises, course: course,
                                        additional_excluded_numbers: core_exercise_numbers)
                             .outputs.exercises

      # Randomize and grab the required numbers of exercises
      chosen_exercises = run(:choose, exercises: filtered_exercises, count: num_requested,
                                      history: history).outputs.exercises

      spaced_practice_status << "Could not completely fill the #{k_ago}-ago slot" \
        if chosen_exercises.size < num_requested

      chosen_exercises
    end.compact

    spaced_practice_status << 'Completely filled' if spaced_practice_status.empty?

    exercises = core_exercises + spaced_exercises
    group_types = core_exercises.map{ :core_group } + \
                  spaced_exercises.map{ :spaced_practice_group }

    related_content_array = exercises.map{ |ex| ex.page.related_content }

    # Create the new concept coach task, and put the exercises into steps
    run(:create_cc_task, role: role, page: page, exercises: exercises,
                         group_types: group_types, related_content_array: related_content_array)

    run(:add_spy_info, to: outputs.task,
                       from: [ecosystem, { history: history.tasks,
                                           spaced_practice: spaced_practice_status }])
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
      valid_books = Content::Models::Book.where(
        content_ecosystem_id: ecosystem_id_role_map.keys
      ).to_a
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
    [ecosystem, page.concept_coach_pool]
  end

end
