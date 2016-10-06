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
  # course is an Entity::Course
  # task is a Tasks::Models::Task
  # student is a CourseMembership::Models::Student
  # book_container is a Content::Chapter or Content::Page or one of their models
  # exercise_id is a String containing an Exercise uuid, number or uid
  # period is a CourseMembership::Period or CourseMembership::Models::Period
  # max_exercises_to_return is an integer

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
                                                    .pluck(:id, :tutor_uuid)
                                                    .index_by(&:first)
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
        container_cnx_identity: chapter.cnx_id,
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
        uuid: exercise.tutor_uuid,
        exercises_uuid: exercise.uuid,
        exercises_version: exercise.version,
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
      course_uuid: request[:course].uuid, ecosystem_uuid: request[:ecosystem].tutor_uuid
    }

    single_api_request url: :create_course, request: biglearn_request
  end

  # Prepares Biglearn for a course ecosystem update
  def prepare_course_ecosystem(request)
    course = request[:course]
    to_ecosystem = Content::Ecosystem.new strategy: request[:ecosystem].to_model.wrap
    from_ecosystem = Content::Ecosystem.new(
      strategy: course.ecosystems.find{ |ecosystem| ecosystem.id != to_ecosystem.id }.wrap
    )
    content_map = Content::Map.find_or_create_by!(
      from_ecosystems: [from_ecosystem], to_ecosystem: to_ecosystem
    )
    cnx_pagemodule_mappings = content_map.map_pages_to_pages(pages: from_ecosystem.pages)
                                         .map do |from_page, to_page|
      { from_cnx_pagemodule_identity: from_page.uuid, to_cnx_pagemodule_identity: to_page.uuid }
    end
    exercise_mappings = content_map.map_exercises_to_pages(exercises: from_ecosystem.exercises)
                                   .map do |exercise, page|
      { from_exercise_uuid: exercise.tutor_uuid, to_cnx_pagemodule_identity: page.uuid }
    end

    biglearn_request = {
      preparation_uuid: request[:preparation_uuid],
      course_uuid: course.uuid,
      ecosystem_map: {
        from_ecosystem_uuid: from_ecosystem.tutor_uuid,
        to_ecosystem_uuid: to_ecosystem.tutor_uuid,
        cnx_pagemodule_mappings: cnx_pagemodule_mappings,
        exercise_mappings: exercise_mappings
      }
    }

    single_api_request url: :prepare_course_ecosystem, request: biglearn_request
  end

  # Finalizes course ecosystem updates in Biglearn,
  # causing it to stop computing CLUes for the old one
  def update_course_ecosystems(requests)
    biglearn_requests = requests.map do |request|
      { request_uuid: request[:request_uuid], preparation_uuid: request[:preparation_uuid] }
    end

    bulk_api_request url: :update_course_ecosystems, requests: biglearn_requests,
                     requests_key: :update_requests, responses_key: :update_responses
  end

  # Updates Course rosters in Biglearn
  def update_rosters(requests)
    biglearn_requests = requests.map do |request|
      course = request[:course]
      course_containers = []
      students = course.periods.flat_map do |period|
        course_containers << { container_uuid: period.uuid, parent_container_uuid: course.uuid }

        period.students.map{ |student| { student_uuid: student.uuid, container_uuid: period.uuid } }
      end

      {
        request_uuid: request[:request_uuid],
        course_uuid: course.uuid,
        sequence_number: course.sequence_number,
        course_containers: course_containers,
        students: students
      }
    end

    bulk_api_request url: :update_rosters, requests: biglearn_requests,
                     requests_key: :rosters, responses_key: :updated_course_uuids, max_requests: 100
  end

  # Updates global exercise exclusions
  def update_global_exercise_exclusions(request)
    # TODO: This API still needs definition
    single_api_request url: :update_global_exercise_exclusions, request: request
  end

  # Updates exercise exclusions for the given course
  def update_course_exercise_exclusions(request)
    # TODO: This API still needs definition
    course = request[:course]
    exercise_ids = course.excluded_exercises.map(&:exercise_number)

    biglearn_request = { course_uuid: course.uuid, exercise_ids: exercise_ids }

    single_api_request url: :update_course_exercise_exclusions, request: biglearn_request
  end

  # Creates or updates tasks in Biglearn
  def create_update_assignments(requests)
    all_tasks = requests.map{ |request| request[:task] }

    task_id_to_core_page_ids_map = GetTaskCorePageIds[tasks: all_tasks]
    all_core_page_ids = task_id_to_core_page_ids_map.values.flatten
    page_id_to_page_uuid_map = Content::Models::Page.where(id: all_core_page_ids)
                                                    .pluck(:id, :tutor_uuid)
                                                    .to_h
    task_id_to_core_page_uuids_map = {}
    task_id_to_core_page_ids_map.each do |task_id, core_page_ids|
      task_id_to_core_page_uuids_map[task_id] = core_page_ids.map do |page_id|
        page_id_to_page_uuid_map[page_id]
      end
    end


    biglearn_requests = requests.map do |request|
      task = request[:task]
      assigned_book_container_uuids = task_id_to_core_page_uuids_map[task.id]
      goal_num_tutor_assigned_spes = task.task_steps.select(&:spaced_practice_group?).length
      spes_are_assigned = true
      goal_num_tutor_assigned_pes = task.task_steps.select(&:personalized_group?).length
      pes_are_assigned = task.placeholder_exercise_steps_count == 0
      assigned_exercises = task.task_steps.select(&:exercise?).map do |exercise_step|
        {
          trial_uuid: exercise_step.tasked.uuid,
          exercise_uuid: exercise_step.tasked.exercise.tutor_uuid,
          is_spe: exercise_step.spaced_practice_group?,
          is_pe: exercise_step.personalized_group?
        }
      end

      {
        request_uuid: request[:request_uuid],
        assignment_uuid: task.uuid,
        sequence_number: task.sequence_number,
        is_deleted: task.deleted?,
        ecosystem_uuid: request[:task].ecosystem.tutor_uuid, # TODO: Add this field?
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

    bulk_api_request url: :fetch_practice_worst_areas_pes, requests: biglearn_requests,
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

    bulk_api_request url: :fetch_student_clues, requests: biglearn_requests,
                     requests_key: :teacher_clue_requests, responses_key: :teacher_clue_responses
  end

  protected

  def absolutize_url(url)
    Addressable::URI.join @server_url, url.to_s
  end

  def single_api_request(method: :post, url:, request:)
    absolute_uri = absolutize_url(url)

    request_options = HEADER_OPTIONS.merge({ body: request.to_json })

    response = (@oauth_token || @oauth_client).request method, absolute_uri, request_options

    response_hash = JSON.parse(response.body).deep_symbolize_keys

    block_given? ? yield(response_hash) : response_hash
  end

  def bulk_api_request(method: :post, url:, requests:,
                       requests_key:, responses_key:, max_requests: 1000)
    absolute_uri = absolutize_url(url)
    max_requests ||= requests.size

    requests.each_slice(max_requests) do |requests|
      requests_json = requests.map(&:to_json)

      request_options = HEADER_OPTIONS.merge({ body: { requests_key => requests_json } })

      response = (@oauth_token || @oauth_client).request method, absolute_uri, request_options

      response_hashes = JSON.parse(response.body).deep_symbolize_keys[responses_key]

      response_hashes.map{ |response_hash| block_given? ? yield(response_hash) : response_hash }
    end
  end

end
