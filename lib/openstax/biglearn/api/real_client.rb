class OpenStax::Biglearn::Api::RealClient

  HEADER_OPTIONS = { headers: { 'Content-Type' => 'application/json' } }.freeze

  def initialize(biglearn_configuration)
    @server_url   = biglearn_configuration.server_url
    @client_id    = biglearn_configuration.client_id
    @secret       = biglearn_configuration.secret

    @oauth_client = OAuth2::Client.new @client_id, @secret, site: @server_url

    @oauth_token  = @oauth_client.client_credentials.get_token unless @client_id.nil?
  end

  def name
    :real
  end

  #
  # API methods
  #

  # ecosystem is a Content::Ecosystem or Content::Models::Ecosystem
  # course is a CourseProfile::Models::Course
  # task is a Tasks::Models::Task
  # student is a CourseMembership::Models::Student
  # book_container is a Content::Chapter or Content::Page or one of their models
  # exercise_id is a String containing an Exercise uuid, number or uid
  # period is a CourseMembership::Period or CourseMembership::Models::Period
  # max_num_exercises is an integer

  # Adds the given ecosystem to Biglearn
  def create_ecosystem(request)
    ecosystem = request[:ecosystem]
    book = ecosystem.books.first
    all_pools = book.chapters.flat_map do |chapter|
      [chapter.all_exercises_pool] + chapter.pages.flat_map do |page|
        [page.all_exercises_pool, page.reading_dynamic_pool,
         page.homework_dynamic_pool, page.concept_coach_pool]
      end
    end
    all_exercise_ids = all_pools.flat_map(&:content_exercise_ids)
    exercise_uuids_by_id = Content::Models::Exercise.where(id: all_exercise_ids)
                                                    .pluck(:id, :uuid)
                                                    .to_h
    exercise_uuids_by_pool = {}
    all_pools.each do |pool|
      exercise_uuids_by_pool[pool] = pool.content_exercise_ids.map do |exercise_id|
        exercise_uuids_by_id[exercise_id]
      end
    end

    contents = [
      {
        container_uuid: book.tutor_uuid,
        container_parent_uuid: ecosystem.tutor_uuid,
        container_cnx_identity: book.cnx_id,
        pools: []
      }
    ]
    book.chapters.each do |chapter|
      pools = [
        {
          use_for_clue: true,
          use_for_personalized_for_assignment_types: [],
          exercise_uuids: exercise_uuids_by_pool[chapter.all_exercises_pool]
        }
      ]

      contents << {
        container_uuid: chapter.tutor_uuid,
        container_parent_uuid: book.tutor_uuid,
        container_cnx_identity: chapter.tutor_uuid,
        pools: pools
      }

      chapter.pages.each do |page|
        pools = [
          {
            use_for_clue: true,
            use_for_personalized_for_assignment_types: [],
            exercise_uuids: exercise_uuids_by_pool[page.all_exercises_pool]
          },
          {
            use_for_clue: false,
            use_for_personalized_for_assignment_types: ['reading'],
            exercise_uuids: exercise_uuids_by_pool[page.reading_dynamic_pool]
          },
          {
            use_for_clue: false,
            use_for_personalized_for_assignment_types: ['homework'],
            exercise_uuids: exercise_uuids_by_pool[page.homework_dynamic_pool]
          },
          {
            use_for_clue: false,
            use_for_personalized_for_assignment_types: ['practice'],
            exercise_uuids: exercise_uuids_by_pool[page.practice_widget_pool]
          },
          {
            use_for_clue: false,
            use_for_personalized_for_assignment_types: ['concept-coach'],
            exercise_uuids: exercise_uuids_by_pool[page.concept_coach_pool]
          }
        ]

        contents << {
          container_uuid: page.tutor_uuid,
          container_parent_uuid: chapter.tutor_uuid,
          container_cnx_identity: page.cnx_id,
          pools: pools
        }
      end
    end

    exercises = ecosystem.exercises.map do |exercise|
      {
        exercise_uuid: exercise.uuid,
        group_uuid: exercise.group_uuid,
        version: exercise.version,
        los: exercise.los.map(&:value)
      }
    end

    biglearn_request = {
      ecosystem_uuid: ecosystem.tutor_uuid,
      book: { cnx_identity: book.cnx_id, contents: contents },
      exercises: exercises
    }

    single_api_request url: :create_ecosystem, request: biglearn_request
  end

  # Adds the given course to Biglearn
  def create_course(request)
    biglearn_request = {
      course_uuid: request[:course].uuid,
      ecosystem_uuid: request[:ecosystem].tutor_uuid
    }

    single_api_request url: :create_course, request: biglearn_request
  end

  # Prepares Biglearn for a course ecosystem update
  def prepare_course_ecosystem(request)
    course = request[:course]
    to_ecosystem_model = request[:ecosystem].to_model
    to_ecosystem = Content::Ecosystem.new strategy: to_ecosystem_model.wrap
    from_ecosystem_model = course.ecosystems.find{ |ecosystem| ecosystem.id != to_ecosystem.id }
    from_ecosystem = Content::Ecosystem.new strategy: from_ecosystem_model.wrap
    content_map = Content::Map.find_or_create_by!(
      from_ecosystems: [from_ecosystem], to_ecosystem: to_ecosystem
    )
    book_container_mappings = content_map.map_pages_to_pages(pages: from_ecosystem.pages)
                                         .map do |from_page, to_page|
      { from_book_container_uuid: from_page.uuid, to_book_container_uuid: to_page.uuid }
    end
    exercise_mappings = content_map.map_exercises_to_pages(exercises: from_ecosystem.exercises)
                                   .map do |exercise, page|
      { from_exercise_uuid: exercise.uuid, to_book_container_uuid: page.uuid }
    end

    biglearn_request = {
      preparation_uuid: request[:preparation_uuid],
      course_uuid: course.uuid,
      sequence_number: request[:sequence_number],
      next_ecosystem_uuid: to_ecosystem.tutor_uuid,
      ecosystem_map: {
        from_ecosystem_uuid: from_ecosystem.tutor_uuid,
        to_ecosystem_uuid: to_ecosystem.tutor_uuid,
        book_container_mappings: book_container_mappings,
        exercise_mappings: exercise_mappings
      }
    }

    single_api_request url: :prepare_course_ecosystem, request: biglearn_request
  end

  # Finalizes course ecosystem updates in Biglearn,
  # causing it to stop computing CLUes for the old one
  def update_course_ecosystems(requests)
    biglearn_requests = requests.map do |request|
      {
        request_uuid: request[:request_uuid],
        course_uuid: request[:course].uuid,
        sequence_number: request[:sequence_number],
        preparation_uuid: request[:preparation_uuid]
      }
    end

    bulk_api_request url: :update_course_ecosystems, requests: biglearn_requests,
                     requests_key: :update_requests, responses_key: :update_responses
  end

  # Updates Course rosters in Biglearn
  def update_rosters(requests)
    biglearn_requests = requests.map do |request|
      course = request[:course]
      course_containers = []
      students = course.periods_with_deleted.flat_map do |period|
        course_containers << {
          container_uuid: period.uuid,
          parent_container_uuid: course.uuid,
          is_archived: period.deleted?
        }

        period.latest_enrollments.map do |enrollment|
          { student_uuid: enrollment.student.uuid, container_uuid: period.uuid }
        end
      end

      {
        request_uuid: request[:request_uuid],
        course_uuid: course.uuid,
        sequence_number: request[:sequence_number],
        course_containers: course_containers,
        students: students
      }
    end

    bulk_api_request url: :update_rosters, requests: biglearn_requests,
                     requests_key: :rosters, responses_key: :updated_rosters, max_requests: 100
  end

  # Updates global exercise exclusions for the given course
  def update_globally_excluded_exercises(request)
    course = request[:course]

    excluded_ids = Settings::Exercises.excluded_ids.split(',').map(&:strip)
    excluded_numbers_and_versions = excluded_ids.map do |number_or_uid|
      number_or_uid.split('@')
    end
    group_numbers, uids = excluded_numbers_and_versions.partition { |ex| ex.second.nil? }

    group_uuids = Content::Models::Exercise.where(number: group_numbers).pluck(:group_uuid)
    group_exclusions = group_uuids.map { |group_uuid| { exercise_group_uuid: group_uuid } }

    uuid_queries = uids.map do |number, version|

    end
    uuids = Content::Models::Exercise.where do
      uids.map { |nn, vv| number.eq(nn).and version.eq(vv) }.join(:or)
    end.pluck(:uuid)
    version_exclusions = uuids.map { |uuid| { exercise_uuid: uuid } }

    exclusions = group_exclusions + version_exclusions

    biglearn_request = {
      request_uuid: SecureRandom.uuid,
      course_uuid: course.uuid,
      sequence_number: request[:sequence_number],
      exclusions: exclusions
    }

    single_api_request url: :update_globally_excluded_exercises, request: biglearn_request
  end

  # Updates exercise exclusions for the given course
  def update_course_excluded_exercises(request)
    course = request[:course]

    group_numbers = course.excluded_exercises.map(&:exercise_number)
    group_uuids = Content::Models::Exercise.where(number: group_numbers).pluck(:group_uuid)
    group_exclusions = group_uuids.map { |group_uuid| { exercise_group_uuid: group_uuid } }

    biglearn_request = {
      request_uuid: SecureRandom.uuid,
      course_uuid: course.uuid,
      sequence_number: request[:sequence_number],
      exclusions: group_exclusions
    }

    single_api_request url: :update_course_excluded_exercises, request: biglearn_request
  end

  # Updates the given course's start/end dates
  def update_course_active_dates(request)
    course = request[:course]

    biglearn_request = {
      request_uuid: SecureRandom.uuid,
      course_uuid: course.uuid,
      sequence_number: request[:sequence_number],
      starts_at: course.starts_at,
      ends_at: course.ends_at
    }

    single_api_request url: :update_course_active_dates, request: biglearn_request
  end

  # Creates or updates tasks in Biglearn
  def create_update_assignments(requests)
    task_id_to_core_page_ids_overrides = {}
    tasks_without_core_page_ids_override = []
    requests.each do |request|
      task = request[:task]

      if request.has_key?(:core_page_ids)
        task_id_to_core_page_ids_overrides[task.id] = request[:core_page_ids]
      else
        tasks_without_core_page_ids_override << task
      end
    end

    task_id_to_core_page_ids_map = GetTaskCorePageIds[tasks: tasks_without_core_page_ids_override]
                                     .merge(task_id_to_core_page_ids_overrides)
    all_core_page_ids = task_id_to_core_page_ids_map.values.flatten
    page_id_to_page_uuid_map = Content::Models::Page.where(id: all_core_page_ids)
                                                    .pluck(:id, :tutor_uuid)
                                                    .to_h

    biglearn_requests = requests.map do |request|
      task = request[:task]
      core_page_ids = task_id_to_core_page_ids_map[task.id]
      assigned_book_container_uuids = core_page_ids.map do |page_id|
        page_id_to_page_uuid_map[page_id]
      end
      goal_num_tutor_assigned_spes = task.task_steps.select(&:spaced_practice_group?).length
      spes_are_assigned = true
      goal_num_tutor_assigned_pes = task.task_steps.select(&:personalized_group?).length
      pes_are_assigned = task.placeholder_exercise_steps_count == 0
      assigned_exercises = task.task_steps.select(&:exercise?).map do |exercise_step|
        {
          trial_uuid: exercise_step.tasked.uuid,
          exercise_uuid: exercise_step.tasked.exercise.uuid,
          is_spe: exercise_step.spaced_practice_group?,
          is_pe: exercise_step.personalized_group?
        }
      end

      {
        request_uuid: request[:request_uuid],
        course_uuid: request[:course].uuid,
        sequence_number: request[:sequence_number],
        assignment_uuid: task.uuid,
        is_deleted: task.deleted?,
        ecosystem_uuid: task.ecosystem.try!(:tutor_uuid),
        student_uuid: task.taskings.first.role.student.uuid,
        assignment_type: task.task_type,
        assigned_book_container_uuids: assigned_book_container_uuids,
        goal_num_tutor_assigned_spes: goal_num_tutor_assigned_spes,
        spes_are_assigned: spes_are_assigned,
        goal_num_tutor_assigned_pes: goal_num_tutor_assigned_pes,
        pes_are_assigned: pes_are_assigned,
        assigned_exercises: assigned_exercises
      }
    end

    bulk_api_request url: :create_update_assignments, requests: biglearn_requests,
                     requests_key: :assignments, responses_key: :updated_assignments
  end

  # Records the given student responses
  def record_responses(requests)
    biglearn_requests = requests.map do |request|
      tasked_exercise = request[:tasked_exercise]

      {
        response_uuid: request[:response_uuid],
        course_uuid: request[:course].uuid,
        sequence_number: request[:sequence_number],
        trial_uuid: tasked_exercise.uuid,
        student_uuid: tasked_exercise.task_step.task.taskings.first.role.student.uuid,
        exercise_uuid: tasked_exercise.exercise.uuid,
        is_correct: tasked_exercise.is_correct?,
        responded_at: tasked_exercise.updated_at
      }
    end

    bulk_api_request(
      url: :record_responses,
      requests: biglearn_requests,
      requests_key: :responses,
      responses_key: :recorded_response_uuids
    ) do |response|
      { response_uuid: response }
    end
  end

  # Returns a number of recommended personalized exercises for the given tasks
  def fetch_assignment_pes(requests)
    biglearn_requests = requests.map do |request|
      {
        request_uuid: request[:request_uuid],
        assignment_uuid: request[:task].uuid,
        max_num_exercises: request[:max_num_exercises]
      }
    end

    bulk_api_request url: :fetch_assignment_pes, requests: biglearn_requests,
                     requests_key: :pe_requests, responses_key: :pe_responses
  end

  # Returns a number of recommended spaced practice exercises for the given tasks
  def fetch_assignment_spes(requests)
    biglearn_requests = requests.map do |request|
      {
        request_uuid: request[:request_uuid],
        assignment_uuid: request[:task].uuid,
        max_num_exercises: request[:max_num_exercises]
      }
    end

    bulk_api_request url: :fetch_assignment_spes, requests: biglearn_requests,
                     requests_key: :spe_requests, responses_key: :spe_responses
  end

  # Returns a number of recommended personalized exercises for the student's worst topics
  def fetch_practice_worst_areas_pes(requests)
    biglearn_requests = requests.map do |request|
      {
        request_uuid: request[:request_uuid],
        student_uuid: request[:student].uuid,
        max_num_exercises: request[:max_num_exercises]
      }
    end

    bulk_api_request url: :fetch_practice_worst_areas_exercises, requests: biglearn_requests,
                     requests_key: :worst_areas_requests, responses_key: :worst_areas_responses
  end

  # Returns the CLUes for the given book containers and students (for students)
  def fetch_student_clues(requests)
    biglearn_requests = requests.map do |request|
      {
        request_uuid: request[:request_uuid],
        student_uuid: request[:student].uuid,
        book_container_uuid: request[:book_container].tutor_uuid
      }
    end

    bulk_api_request url: :fetch_student_clues, requests: biglearn_requests,
                     requests_key: :student_clue_requests, responses_key: :student_clue_responses
  end

  # Returns the CLUes for the given book containers and periods (for teachers)
  def fetch_teacher_clues(requests)
    biglearn_requests = requests.map do |request|
      {
        request_uuid: request[:request_uuid],
        course_container_uuid: request[:course_container].uuid,
        book_container_uuid: request[:book_container].tutor_uuid
      }
    end

    bulk_api_request url: :fetch_teacher_clues, requests: biglearn_requests,
                     requests_key: :teacher_clue_requests, responses_key: :teacher_clue_responses
  end

  protected

  def absolutize_url(url)
    Addressable::URI.join @server_url, url.to_s
  end

  def api_request(method:, url:, body:)
    absolute_uri = absolutize_url(url)

    request_options = HEADER_OPTIONS.merge({ body: body.to_json })

    response = (@oauth_token || @oauth_client).request method, absolute_uri, request_options

    JSON.parse(response.body).deep_symbolize_keys
  end

  def single_api_request(method: :post, url:, request:)
    response_hash = api_request method: method, url: url, body: request

    block_given? ? yield(response_hash) : response_hash
  end

  def bulk_api_request(method: :post, url:, requests:,
                       requests_key:, responses_key:, max_requests: 1000)
    max_requests ||= requests.size

    requests.each_slice(max_requests).flat_map do |requests|
      body = { requests_key => requests }

      response_hash = api_request method: method, url: url, body: body

      responses_array = response_hash[responses_key]

      responses_array.map{ |response| block_given? ? yield(response) : response }
    end
  end

end
