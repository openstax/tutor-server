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

  def exec(user:, book_uuid:, page_uuid:)
    role, book = get_role_and_book(user: user, book_uuid: book_uuid)
    page = book.pages.find{ |page| page.uuid == page_uuid }
    fatal_error(code: :invalid_page) if page.nil?

    course = role.student.course
    ecosystem = book.ecosystem
    pool = page.concept_coach_pool

    history = run(:get_history, roles: role, type: :concept_coach).outputs.history[role]
    existing_cc_task = run(:get_cc_task, role: role, page: page).outputs.task
    unless existing_cc_task.nil?
      outputs.task = existing_cc_task
      spy_history = history.core_page_ids.map{ |page_ids| { page_id: page_ids.first } }
      run(:add_spy_info, to: outputs.task, from: [ecosystem, { history: spy_history }])
      return
    end

    pool_exercises = pool.exercises.uniq
    filtered_exercises = run(:filter, exercises: pool_exercises, course: course).outputs.exercises
    core_exercises = run(:choose, exercises: filtered_exercises,
                                  count: Tasks::Models::ConceptCoachTask::CORE_EXERCISES_COUNT,
                                  history: history,
                                  allow_repeats: false).outputs.exercises

    if core_exercises.empty?
      outputs.valid_book_urls = ecosystem.books.map(&:url)
      fatal_error(code: :page_has_no_exercises)
    end

    core_exercise_numbers = core_exercises.map(&:number)
    ecosystems_map = {}

    spaced_page_ids = history.core_page_ids

    spaced_practice_status = []

    # Prepare eligible random-ago pages, but only if we have 4 or more tasks
    if history.total_count >= 4
      random_page_ids = spaced_page_ids.dup
      forbidden_random_ks = Tasks::Models::ConceptCoachTask::SPACED_EXERCISES_MAP
                              .map(&:first).select{ |k_ago| k_ago != :random }.uniq
      forbidden_random_ks.sort.reverse.each do |forbidden_random_k|
        # Subtract 1 from k_ago because this history does not include the current task (0-ago)
        random_page_ids.delete_at(forbidden_random_k - 1)
      end
    end

    k_ago_map = Tasks::Models::ConceptCoachTask::SPACED_EXERCISES_MAP
    spaced_exercises = k_ago_map.flat_map do |k_ago, num_requested|
      # Do not do random-ago if less than 4 past tasks in history
      if k_ago == :random && history.total_count < 4
        spaced_practice_status << "Random-ago slot skipped because < 4 tasks in past history"
        next
      end

      # Select a pages from a CC task
      chosen_page_ids = k_ago == :random ? random_page_ids.sample : spaced_page_ids[k_ago - 1]

      # Skip if no k_ago task
      if chosen_page_ids.blank?
        spaced_practice_status << "Not enough tasks in history to fill the #{k_ago}-ago slot"
        next
      end

      # CC tasks only have 1 page
      chosen_page_id = chosen_page_ids.first

      spaced_page_model = Content::Models::Page.find(chosen_page_id)
      spaced_page = Content::Page.new(strategy: spaced_page_model.wrap)
      spaced_ecosystem = Content::Ecosystem.find_by_page_ids(spaced_page.id)
      ecosystems_map[spaced_ecosystem.id] ||= Content::Map.find_or_create_by(
        from_ecosystems: [spaced_ecosystem, ecosystem].uniq, to_ecosystem: ecosystem
      )

      # Map the spaced page to exercises in the current task's ecosystem
      spaced_exercises = ecosystems_map[spaced_ecosystem.id].map_pages_to_exercises(
        pages: spaced_page, pool_type: :concept_coach
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
    group_types = core_exercises.map{ :core_group } + spaced_exercises.map{ :spaced_practice_group }

    related_content_array = exercises.map{ |ex| ex.page.related_content }

    # Create the new concept coach task, and put the exercises into steps
    run(:create_cc_task, role: role, page: page, exercises: exercises,
                         group_types: group_types, related_content_array: related_content_array)

    run(:add_spy_info, to: outputs.task,
                       from: [ecosystem, { history: history.core_page_ids,
                                           spaced_practice: spaced_practice_status }])

    OpenStax::Biglearn::Api.create_update_assignments(course: course, task: outputs.task)
  end

  def get_role_and_book(user:, book_uuid:)
    roles = Role::GetUserRoles[user, :student]

    cc_roles = roles.select{ |role| role.student.try!(:course).try!(:is_concept_coach) }

    valid_books = []
    selected_role_book_array_array = []
    cc_roles.each do |role|
      books = run(:get_ecosystem, course: role.student.course).outputs.ecosystem.books
      valid_books += books
      selected_book = books.find{ |book| book.uuid == book_uuid }
      selected_role_book_array_array << [role, selected_book] unless selected_book.nil?
    end

    outputs.valid_book_urls = valid_books.map(&:url).uniq

    fatal_error(code: :not_a_cc_student) if outputs.valid_book_urls.empty?

    fatal_error(code: :invalid_book) if selected_role_book_array_array.empty?

    # If we have more than 1 role, the user is in multiple CC courses with the same book
    # In that case, select their latest enrollment as the active one
    selected_role_book_array_array.max_by{ |role, book| role.student.latest_enrollment.created_at }
  end

end
