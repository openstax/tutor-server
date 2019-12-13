# Requests that get this far MUST reach biglearn-api
# or else they will introduce gaps in the sequence_number
# If aborting a request in here is required in the future,
# instead send a no-op event to biglearn-api
class OpenStax::Biglearn::Api::RealClient < OpenStax::Biglearn::RealClient
  include OpenStax::Biglearn::Api::Client

  # ecosystem is a Content::Models::Ecosystem or Content::Models::Ecosystem
  # course is a CourseProfile::Models::Course
  # task is a Tasks::Models::Task
  # student is a CourseMembership::Models::Student
  # book_container is a Content::Chapter or Content::Page or one of their models
  # exercise_id is a String containing an Exercise uuid, number or uid
  # period is a CourseMembership::Models::Period
  # max_num_exercises is an integer

  # Adds the given ecosystem to Biglearn
  def create_ecosystem(request)
    ecosystem = request.fetch(:ecosystem)
    # Assumes ecosystems only have 1 book
    book = ecosystem.books.first
    page_uuid_by_id = book.pages.pluck(:id, :uuid).to_h
    exercises = ecosystem.exercises.preload(:tags)
    exercise_uuid_by_id = {}
    exercises.each { |exercise| exercise_uuid_by_id[exercise.id] = exercise.uuid }

    contents = get_containers ecosystem, book, exercise_uuid_by_id

    exercise_requests = exercises.map do |exercise|
      {
        exercise_uuid: exercise.uuid,
        group_uuid: exercise.group_uuid,
        version: exercise.version,
        los: (
          [ "cnxmod:#{page_uuid_by_id[exercise.content_page_id]}" ] + exercise.los.map(&:value)
        ).uniq
      }
    end

    biglearn_request = {
      ecosystem_uuid: ecosystem.tutor_uuid,
      book: { cnx_identity: book.cnx_id, contents: contents },
      exercises: exercise_requests,
      imported_at: ecosystem.created_at.utc.iso8601(6)
    }

    single_api_request url: :create_ecosystem, request: biglearn_request
  end

  # Adds the given course to Biglearn
  def create_course(request)
    course = request.fetch(:course)

    biglearn_request = {
      course_uuid: course.uuid,
      ecosystem_uuid: request.fetch(:ecosystem).tutor_uuid,
      is_real_course: !course.is_preview && !course.is_test,
      starts_at: course.starts_at.utc.iso8601(6),
      ends_at: course.ends_at.utc.iso8601(6),
      created_at: course.created_at.utc.iso8601(6)
    }

    single_api_request url: :create_course, request: biglearn_request
  end

  # Prepares Biglearn for a course ecosystem update
  def prepare_course_ecosystem(request)
    course = request.fetch(:course)
    from_ecosystem = request.fetch(:from_ecosystem)
    to_ecosystem = request.fetch(:to_ecosystem)
    content_map = Content::Map.find_or_create_by(
      from_ecosystems: [ from_ecosystem ], to_ecosystem: to_ecosystem
    )

    page_uuid_by_id = (
      from_ecosystem.pages.pluck(:id, :uuid) + to_ecosystem.pages.pluck(:id, :tutor_uuid)
    ).to_h
    book_container_mappings = content_map.map_page_ids(page_ids: page_uuid_by_id.keys)
                                         .map do |from_page_id, to_page_id|
      next if to_page_id.nil?

      {
        from_book_container_uuid: page_uuid_by_id[from_page_id],
        to_book_container_uuid: page_uuid_by_id[to_page_id]
      }
    end.compact

    exercise_uuid_by_id = from_ecosystem.exercises.pluck(:id, :uuid).to_h
    exercise_mappings = content_map.map_exercise_ids_to_page_ids(
      exercise_ids: exercise_uuid_by_id.keys
    ).map do |exercise_id, page_id|
      next if page_id.nil?

      {
        from_exercise_uuid: exercise_uuid_by_id[exercise_id],
        to_book_container_uuid: page_uuid_by_id[page_id]
      }
    end.compact

    prepared_at = request[:prepared_at] || course.course_ecosystems.find do |ce|
      ce.content_ecosystem_id == to_ecosystem.id
    end&.created_at || Time.current

    biglearn_request = {
      preparation_uuid: request.fetch(:preparation_uuid),
      course_uuid: course.uuid,
      sequence_number: request.fetch(:sequence_number),
      next_ecosystem_uuid: to_ecosystem.tutor_uuid,
      ecosystem_map: {
        from_ecosystem_uuid: from_ecosystem.tutor_uuid,
        to_ecosystem_uuid: to_ecosystem.tutor_uuid,
        book_container_mappings: book_container_mappings,
        exercise_mappings: exercise_mappings
      },
      prepared_at: prepared_at.utc.iso8601(6)
    }

    single_api_request url: :prepare_course_ecosystem, request: biglearn_request
  end

  # Finalizes course ecosystem updates in Biglearn,
  # causing it to stop computing CLUes for the old one
  def update_course_ecosystems(requests)
    biglearn_requests = requests.map do |request|
      course = request.fetch(:course)
      updated_at = request[:updated_at] ||
                   course.course_ecosystems.first&.created_at ||
                   Time.current

      {
        request_uuid: request.fetch(:request_uuid),
        course_uuid: course.uuid,
        sequence_number: request.fetch(:sequence_number),
        preparation_uuid: request.fetch(:preparation_uuid),
        updated_at: updated_at.utc.iso8601(6)
      }
    end

    bulk_api_request url: :update_course_ecosystems, requests: biglearn_requests,
                     requests_key: :update_requests, responses_key: :update_responses
  end

  # Updates Course rosters in Biglearn
  def update_rosters(requests)
    biglearn_requests = requests.map do |request|
      course = request.fetch(:course)
      course_containers = []
      students = course.periods.flat_map do |period|
        course_containers << {
          container_uuid: period.uuid,
          parent_container_uuid: course.uuid,
          created_at: period.created_at.utc.iso8601(6)
        }.tap do |hash|
          hash[:archived_at] = period.archived_at.utc.iso8601(6) if period.archived?
        end

        period.latest_enrollments.map do |enrollment|
          student = enrollment.student

          {
            student_uuid: student.uuid,
            container_uuid: period.uuid,
            enrolled_at: student.created_at.utc.iso8601(6),
            last_course_container_change_at: enrollment.created_at.utc.iso8601(6)
          }.tap do |hash|
            hash[:dropped_at] = student.dropped_at.utc.iso8601(6) if student.dropped?
          end
        end + period.teacher_students.map do |teacher_student|
          {
            student_uuid: teacher_student.uuid,
            container_uuid: period.uuid,
            enrolled_at: teacher_student.created_at.utc.iso8601(6),
            last_course_container_change_at: teacher_student.created_at.utc.iso8601(6)
          }.tap do |hash|
            hash[:dropped_at] = teacher_student.deleted_at.utc.iso8601(6) \
              if teacher_student.deleted?
          end
        end
      end

      {
        request_uuid: request.fetch(:request_uuid),
        course_uuid: course.uuid,
        sequence_number: request.fetch(:sequence_number),
        course_containers: course_containers,
        students: students
      }
    end.compact

    bulk_api_request url: :update_rosters, requests: biglearn_requests,
                     requests_key: :rosters, responses_key: :updated_rosters, max_requests: 100
  end

  # Updates global exercise exclusions for the given course
  def update_globally_excluded_exercises(request)
    course = request.fetch(:course)

    excluded_ids = Settings::Exercises.excluded_ids.split(',').map(&:strip)
    excluded_numbers_and_versions = excluded_ids.map do |number_or_uid|
      number_or_uid.split('@')
    end
    group_numbers, uids = excluded_numbers_and_versions.partition { |ex| ex.second.nil? }

    group_uuids = Content::Models::Exercise.where(number: group_numbers).distinct.pluck(:group_uuid)
    group_exclusions = group_uuids.map { |group_uuid| { exercise_group_uuid: group_uuid } }

    version_exclusions = if uids.empty?
      []
    else
      ex = Content::Models::Exercise.arel_table
      Content::Models::Exercise.distinct.where(
        uids.map { |nn, vv| ex[:number].eq(nn).and(ex[:version].eq(vv)) }.reduce(:or)
      ).pluck(:uuid).map { |uuid| { exercise_uuid: uuid } }
    end

    exclusions = group_exclusions + version_exclusions

    updated_at = Settings::Exercises.excluded_at || Time.current

    biglearn_request = {
      request_uuid: request.fetch(:request_uuid),
      course_uuid: course.uuid,
      sequence_number: request.fetch(:sequence_number),
      exclusions: exclusions,
      updated_at: updated_at.utc.iso8601(6)
    }

    single_api_request url: :update_globally_excluded_exercises, request: biglearn_request
  end

  # Updates exercise exclusions for the given course
  def update_course_excluded_exercises(request)
    course = request.fetch(:course)

    group_numbers = course.excluded_exercises.map(&:exercise_number)
    group_uuids = Content::Models::Exercise.where(number: group_numbers).distinct.pluck(:group_uuid)
    group_exclusions = group_uuids.map { |group_uuid| { exercise_group_uuid: group_uuid } }

    biglearn_request = {
      request_uuid: request.fetch(:request_uuid),
      course_uuid: course.uuid,
      sequence_number: request.fetch(:sequence_number),
      exclusions: group_exclusions,
      updated_at: course.updated_at.utc.iso8601(6)
    }

    single_api_request url: :update_course_excluded_exercises, request: biglearn_request
  end

  # Updates the given course's start/end dates
  def update_course_active_dates(request)
    course = request.fetch(:course)

    biglearn_request = {
      request_uuid: request.fetch(:request_uuid),
      course_uuid: course.uuid,
      sequence_number: request.fetch(:sequence_number),
      starts_at: course.starts_at,
      ends_at: course.ends_at,
      updated_at: course.updated_at.utc.iso8601(6)
    }

    single_api_request url: :update_course_active_dates, request: biglearn_request
  end

  # Creates or updates tasks in Biglearn
  def create_update_assignments(requests)
    task_id_to_core_page_ids_overrides = {}
    tasks_without_core_page_ids_override = []
    requests.each do |request|
      task = request.fetch(:task)

      if request.has_key?(:core_page_ids)
        task_id_to_core_page_ids_overrides[task.id] = request.fetch(:core_page_ids)
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
      task = request.fetch(:task)
      # OpenStax::Biglearn::Api already checked that the course_member exists
      student = task.taskings.first.role.course_member

      ecosystem = task.ecosystem

      task_type = task.practice? ? 'practice' : task.task_type

      opens_at = task.opens_at
      due_at = task.due_at

      exclusion_info = {}
      exclusion_info[:opens_at] = opens_at.utc.iso8601(6) if opens_at.present?
      exclusion_info[:due_at] = due_at.utc.iso8601(6) if due_at.present?

      pe_calculation_uuid = task.pe_calculation_uuid
      pe_ecosystem_matrix_uuid = task.pe_ecosystem_matrix_uuid
      spe_calculation_uuid = task.spe_calculation_uuid
      spe_ecosystem_matrix_uuid = task.spe_ecosystem_matrix_uuid

      pes = {}
      pes[:calculation_uuid] = pe_calculation_uuid if pe_calculation_uuid.present?
      pes[:ecosystem_matrix_uuid] = pe_ecosystem_matrix_uuid if pe_ecosystem_matrix_uuid.present?

      spes = {}
      spes[:calculation_uuid] = spe_calculation_uuid if spe_calculation_uuid.present?
      spes[:ecosystem_matrix_uuid] = spe_ecosystem_matrix_uuid if spe_ecosystem_matrix_uuid.present?

      core_page_ids = task_id_to_core_page_ids_map[task.id]
      assigned_book_container_uuids = core_page_ids.map do |page_id|
        page_id_to_page_uuid_map[page_id]
      end
      assigned_exercises = task.tasked_exercises.preload(:task_step, :exercise).map do |te|
        {
          trial_uuid: te.uuid,
          exercise_uuid: te.exercise.uuid,
          is_spe: te.task_step.spaced_practice_group?,
          is_pe: te.task_step.personalized_group?
        }
      end

      # Calculate desired number of SPEs and PEs
      goal_num_tutor_assigned_spes = request[:goal_num_tutor_assigned_spes]
      if goal_num_tutor_assigned_spes.nil?
        sp_steps = task.task_steps.spaced_practice_group.to_a
        spe_steps = sp_steps.select { |step| step.exercise? || step.placeholder? }
        goal_num_tutor_assigned_spes = spe_steps.size
      end

      goal_num_tutor_assigned_pes = request[:goal_num_tutor_assigned_pes]
      if goal_num_tutor_assigned_pes.nil?
        if task.practice?
          goal_num_tutor_assigned_pes = CreatePracticeTaskRoutine::NUM_BIGLEARN_EXERCISES
        else
          p_steps = task.task_steps.personalized_group.to_a
          pe_steps = p_steps.select { |step| step.exercise? || step.placeholder? }
          goal_num_tutor_assigned_pes = pe_steps.size
        end
      end

      {
        request_uuid: request.fetch(:request_uuid),
        course_uuid: request.fetch(:course).uuid,
        sequence_number: request.fetch(:sequence_number),
        assignment_uuid: task.uuid,
        is_deleted: task.withdrawn?,
        ecosystem_uuid: ecosystem.tutor_uuid,
        student_uuid: student.uuid,
        assignment_type: task_type,
        exclusion_info: exclusion_info,
        pes: pes,
        spes: spes,
        assigned_book_container_uuids: assigned_book_container_uuids,
        goal_num_tutor_assigned_spes: goal_num_tutor_assigned_spes,
        spes_are_assigned: task.spes_are_assigned,
        goal_num_tutor_assigned_pes: goal_num_tutor_assigned_pes,
        pes_are_assigned: task.pes_are_assigned,
        assigned_exercises: assigned_exercises,
        created_at: task.created_at.utc.iso8601(6),
        updated_at: task.updated_at.utc.iso8601(6)
      }
    end

    bulk_api_request url: :create_update_assignments, requests: biglearn_requests,
                     requests_key: :assignments, responses_key: :updated_assignments
  end

  # Records the given student responses
  def record_responses(requests)
    biglearn_requests = requests.map do |request|
      tasked_exercise = request.fetch(:tasked_exercise)
      task = tasked_exercise.task_step.task
      role = task.taskings.first&.role
      next if role.nil?

      student = role.course_member
      next if student.nil?

      course = request.fetch(:course)

      {
        response_uuid: request.fetch(:response_uuid),
        course_uuid: course.uuid,
        sequence_number: request.fetch(:sequence_number),
        ecosystem_uuid: task.ecosystem.tutor_uuid,
        trial_uuid: tasked_exercise.uuid,
        student_uuid: student.uuid,
        exercise_uuid: tasked_exercise.exercise.uuid,
        is_correct: tasked_exercise.is_correct?,
        is_real_response: !course.is_preview && !course.is_test && !role.teacher_student?,
        responded_at: tasked_exercise.updated_at.utc.iso8601(6)
      }
    end.compact

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
      task = request.fetch(:task)
      course = task.taskings.first&.role&.course
      next if course.nil?

      max_num_exercises = request[:max_num_exercises]
      algorithm_name = course.biglearn_assignment_pes_algorithm_name ||
                       Settings::Biglearn.assignment_pes_algorithm_name.to_s

      {
        request_uuid: request.fetch(:request_uuid),
        assignment_uuid: task.uuid,
        algorithm_name: algorithm_name
      }.tap do |biglearn_request|
        biglearn_request[:max_num_exercises] = max_num_exercises unless max_num_exercises.nil?
      end
    end

    bulk_api_request url: :fetch_assignment_pes, requests: biglearn_requests,
                     requests_key: :pe_requests, responses_key: :pe_responses
  end

  # Returns a number of recommended spaced practice exercises for the given tasks
  def fetch_assignment_spes(requests)
    biglearn_requests = requests.map do |request|
      task = request.fetch(:task)
      course = task.taskings.first&.role&.course
      next if course.nil?

      max_num_exercises = request[:max_num_exercises]
      algorithm_name = course.biglearn_assignment_spes_algorithm_name ||
                       Settings::Biglearn.assignment_spes_algorithm_name.to_s

      {
        request_uuid: request.fetch(:request_uuid),
        assignment_uuid: task.uuid,
        algorithm_name: algorithm_name
      }.tap do |biglearn_request|
        biglearn_request[:max_num_exercises] = max_num_exercises unless max_num_exercises.nil?
      end
    end

    bulk_api_request url: :fetch_assignment_spes, requests: biglearn_requests,
                     requests_key: :spe_requests, responses_key: :spe_responses
  end

  # Returns a number of recommended personalized exercises for the student's worst topics
  def fetch_practice_worst_areas_exercises(requests)
    biglearn_requests = requests.map do |request|
      student = request.fetch(:student)
      course = student.course
      max_num_exercises = request[:max_num_exercises]
      algorithm_name = course.biglearn_practice_worst_areas_algorithm_name ||
                       Settings::Biglearn.practice_worst_areas_algorithm_name.to_s

      {
        request_uuid: request.fetch(:request_uuid),
        student_uuid: student.uuid,
        algorithm_name: algorithm_name
      }.tap do |biglearn_request|
        biglearn_request[:max_num_exercises] = max_num_exercises unless max_num_exercises.nil?
      end
    end

    bulk_api_request url: :fetch_practice_worst_areas_exercises, requests: biglearn_requests,
                     requests_key: :worst_areas_requests, responses_key: :worst_areas_responses
  end

  # Returns the CLUes for the given book containers and students (for students)
  def fetch_student_clues(requests)
    biglearn_requests = requests.map do |request|
      student = request.fetch(:student)
      course = student.course
      algorithm_name = course.biglearn_student_clues_algorithm_name ||
                       Settings::Biglearn.student_clues_algorithm_name.to_s
      {
        request_uuid: request.fetch(:request_uuid),
        student_uuid: student.uuid,
        book_container_uuid: request.fetch(:book_container_uuid),
        algorithm_name: algorithm_name
      }
    end

    bulk_api_request url: :fetch_student_clues, requests: biglearn_requests,
                     requests_key: :student_clue_requests, responses_key: :student_clue_responses
  end

  # Returns the CLUes for the given book containers and periods (for teachers)
  def fetch_teacher_clues(requests)
    biglearn_requests = requests.map do |request|
      course_container = request.fetch(:course_container)
      course = course_container.course
      algorithm_name = course.biglearn_teacher_clues_algorithm_name ||
                       Settings::Biglearn.teacher_clues_algorithm_name.to_s
      {
        request_uuid: request.fetch(:request_uuid),
        course_container_uuid: course_container.uuid,
        book_container_uuid: request.fetch(:book_container_uuid),
        algorithm_name: algorithm_name
      }
    end

    bulk_api_request url: :fetch_teacher_clues, requests: biglearn_requests,
                     requests_key: :teacher_clue_requests, responses_key: :teacher_clue_responses
  end

  protected

  def token_header
    'Biglearn-Api-Token'
  end

  def get_containers(parent, container, exercise_uuid_by_id)
    pools = [
      {
        use_for_clue: true,
        use_for_personalized_for_assignment_types: [],
        exercise_uuids: exercise_uuid_by_id.values_at(*container.all_exercise_ids)
      }
    ]

    pools.concat(
      [
        {
          use_for_clue: false,
          use_for_personalized_for_assignment_types: ['reading'],
          exercise_uuids: exercise_uuid_by_id.values_at(*container.reading_dynamic_exercise_ids)
        },
        {
          use_for_clue: false,
          use_for_personalized_for_assignment_types: ['homework'],
          exercise_uuids: exercise_uuid_by_id.values_at(*container.homework_dynamic_exercise_ids)
        },
        {
          use_for_clue: false,
          use_for_personalized_for_assignment_types: ['practice'],
          exercise_uuids: exercise_uuid_by_id.values_at(*container.practice_widget_exercise_ids)
        }
      ]
    ) if container.is_a?(Content::Page)

    containers = [
      {
        container_uuid: container.tutor_uuid,
        container_parent_uuid: parent.tutor_uuid,
        container_cnx_identity: container.cnx_id,
        pools: pools
      }
    ]

    containers.concat(
      container.children.flat_map { |child| get_containers container, child, exercise_uuid_by_id }
    ) if container.respond_to?(:children)

    containers
  end
end
