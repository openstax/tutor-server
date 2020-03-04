class OpenStax::Biglearn::Api::FakeClient < OpenStax::Biglearn::FakeClient
  CLUE_MIN_NUM_RESPONSES = 3 # Must be 2 or more to prevent division by 0
  CLUE_Z_ALPHA = 0.68
  CLUE_Z_ALPHA_SQUARED = CLUE_Z_ALPHA**2

  include OpenStax::Biglearn::Api::Client

  attr_reader :store

  def initialize(api_configuration)
    @store = api_configuration.fake_store
  end

  def reset!
    store.clear
  end

  # ecosystem is a Content::Models::Ecosystem or Content::Models::Ecosystem
  # course is a CourseProfile::Models::Course
  # task is a Tasks::Models::Task
  # student is a CourseMembership::Models::Student
  # book_container is a Content::Chapter or Content::Page or one of their models
  # exercise_id is a String containing an Exercise uuid, number or uid
  # period is a CourseMembership::Models::Period
  # max_num_exercises is an integer

  # Adds the given ecosystem to Biglearn
  # Ignored in the FakeClient
  def create_ecosystem(request)
    { created_ecosystem_uuid: request[:ecosystem].tutor_uuid }
  end

  # Adds the given course to Biglearn
  # Ignored in the FakeClient
  def create_course(request)
    { created_course_uuid: request[:course].uuid }
  end

  # Prepares Biglearn for a course ecosystem update
  # Ignored in the FakeClient
  def prepare_course_ecosystem(request)
    { status: 'accepted' }
  end

  # Finalizes course ecosystem updates in Biglearn,
  # causing it to stop computing CLUes for the old one
  # Ignored in the FakeClient
  def update_course_ecosystems(requests)
    requests.map do |request|
      {
        request_uuid: request[:request_uuid],
        update_status: 'updated_and_ready'
      }
    end
  end

  # Updates Course rosters in Biglearn
  # Ignored in the FakeClient
  def update_rosters(requests)
    requests.map do |request|
      {
        request_uuid: request[:request_uuid],
        updated_course_uuid: request[:course].uuid
      }
    end
  end

  # Updates global exercise exclusions
  # Ignored in the FakeClient
  def update_globally_excluded_exercises(request)
    { status: 'success' }
  end

  # Updates exercise exclusions for the given course
  def update_course_excluded_exercises(request)
    { status: 'success' }
  end

  # Updates the given course's active dates
  def update_course_active_dates(request)
    { updated_course_uuid: request[:course].uuid }
  end

  # Creates or updates tasks in Biglearn
  # In FakeClient, stores the (correct) list of PEs for the task for later use
  def create_update_assignments(requests)
    tasks_without_core_page_ids_override = []
    task_id_to_core_page_ids_overrides = {}
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
    page_id_to_page_map = Content::Models::Page.where(id: all_core_page_ids).index_by(&:id)

    # Do some queries to get the dynamic exercises for each assignment type
    task_to_pe_ids_map = {}
    requests.each do |request|
      task = request[:task]

      pe_pool_method = case task.task_type&.to_sym
      when :reading
        :reading_dynamic_exercise_ids
      when :homework
        :homework_dynamic_exercise_ids
      else # Assuming it is one of the different types of practice tasks
        :practice_widget_exercise_ids
      end

      core_page_ids = task_id_to_core_page_ids_map[task.id]

      task_to_pe_ids_map[task] = core_page_ids.flat_map do |page_id|
        page = page_id_to_page_map[page_id]

        page.send(pe_pool_method)
      end
    end

    all_pe_ids = task_to_pe_ids_map.values.flatten

    # Get the uuids for each dynamic exercise id
    pe_id_to_pe_uuid_map = Content::Models::Exercise.where(id: all_pe_ids).pluck(:id, :uuid).to_h

    task_to_pe_ids_map.each do |task, pe_ids|
      task_key = "tasks/#{task.uuid}/pe_uuids"

      pe_uuids = pe_ids.map { |pe_id| pe_id_to_pe_uuid_map[pe_id] }

      store.write task_key, pe_uuids.to_json
    end

    requests.map do |request|
      course = request[:course]
      task = request[:task]

      {
        request_uuid: request[:request_uuid],
        updated_assignment_uuid: task.uuid
      }
    end
  end

  # Records the given student responses
  def record_responses(requests)
    requests.map { |request| request.slice :response_uuid }
  end

  # Returns a number of recommended personalized exercises for the given tasks
  # In the FakeClient, always returns random PEs from the (correct) list of possible PEs
  def fetch_assignment_pes(requests)
    request_task_keys_map = {}
    requests.each do |request|
      request_task_keys_map[request] = "tasks/#{request[:task].uuid}/pe_uuids"
    end

    exercise_uuids_map = store.read_multi(*request_task_keys_map.values)

    requests.map do |request|
      request_uuid = request[:request_uuid]
      task = request[:task]

      num_exercise_uuids = request[:max_num_exercises] || (task.practice? ? 5 : 3)

      if num_exercise_uuids == 0
        {
          request_uuid: request_uuid,
          assignment_uuid: task.uuid,
          exercise_uuids: [],
          assignment_status: 'assignment_ready',
          spy_info: {}
        }
      else
        task_key = request_task_keys_map[request]
        all_exercise_uuids_json = exercise_uuids_map[task_key]

        if all_exercise_uuids_json.nil?
          {
            request_uuid: request_uuid,
            assignment_uuid: task.uuid,
            exercise_uuids: [],
            assignment_status: 'assignment_unknown',
            spy_info: {}
          }
        else
          all_exercise_uuids = JSON.parse all_exercise_uuids_json
          candidate_exercise_uuids = \
            all_exercise_uuids - task.exercise_steps.map { |ts| ts.tasked.exercise.uuid }

          {
            request_uuid: request_uuid,
            assignment_uuid: task.uuid,
            exercise_uuids: candidate_exercise_uuids.sample(num_exercise_uuids),
            assignment_status: 'assignment_ready',
            spy_info: {}
          }
        end
      end
    end
  end

  # Returns a number of recommended spaced practice exercises for the given tasks
  # In the FakeClient, we pretend there are no Spaced Practice exercises,
  # which causes us to return Personalized exercises instead
  def fetch_assignment_spes(requests)
    fetch_assignment_pes(requests)
  end

  # Returns a number of recommended personalized exercises for the student's worst topics
  # Always returns 5 random exercises from the correct ecosystem in the FakeClient
  def fetch_practice_worst_areas_exercises(requests)
    requests.map do |request|
      ecosystem = request.fetch(:student).course.ecosystem
      exercises = ecosystem.nil? ? [] : ecosystem.exercises.sample(5)

      {
        request_uuid: request[:request_uuid],
        student_uuid: request[:student].uuid,
        exercise_uuids: exercises.map(&:uuid),
        student_status: 'student_ready',
        spy_info: {}
      }
    end
  end

  # Returns the CLUes for the given book containers and students (for students)
  # The FakeClient performs the same calculation as biglearn-local-query
  def fetch_student_clues(requests)
    requests.map do |request|
      student = request.fetch(:student)
      student_uuids = [ student.uuid ]
      ecosystem_uuid = student.course.ecosystem

      {
        request_uuid: request[:request_uuid],
        clue_data: calculate_clue(student_uuids: student_uuids, ecosystem_uuid: ecosystem_uuid),
        clue_status: 'clue_ready'
      }
    end
  end

  # Returns the CLUes for the given book containers and periods (for teachers)
  # The FakeClient performs the same calculation as biglearn-local-query
  def fetch_teacher_clues(requests)
    requests.map do |request|
      period = request.fetch(:course_container)
      student_uuids = period.students.map(&:uuid)
      ecosystem_uuid = period.course.ecosystem.tutor_uuid

      {
        request_uuid: request[:request_uuid],
        clue_data: calculate_clue(student_uuids: student_uuids, ecosystem_uuid: ecosystem_uuid),
        clue_status: 'clue_ready'
      }
    end
  end

  protected

  def calculate_clue(student_uuids:, ecosystem_uuid:)
    tasked_exercises = Tasks::Models::TaskedExercise.select(:answer_id, :correct_answer_id).joins(
      task_step: { task: { taskings: { role: :student } } }
    ).where(task_step: { task: { taskings: { role: { student: { uuid: student_uuids } } } } }).to_a
    responses = tasked_exercises.map(&:is_correct?)

    num_responses = responses.size
    if num_responses >= CLUE_MIN_NUM_RESPONSES
      num_correct = responses.count { |bool| bool }

      p_hat = (num_correct + 0.5 * CLUE_Z_ALPHA_SQUARED) / (num_responses + CLUE_Z_ALPHA_SQUARED)

      variance = responses.map do |correct|
        (p_hat - (correct ? 1 : 0))**2
      end.sum / (num_responses - 1)

      interval_delta = (
        CLUE_Z_ALPHA * Math.sqrt(p_hat * (1 - p_hat)/(num_responses + CLUE_Z_ALPHA_SQUARED)) +
        0.1 * Math.sqrt(variance) + 0.05
      )

      {
        minimum: [p_hat - interval_delta, 0].max,
        most_likely: p_hat,
        maximum: [p_hat + interval_delta, 1].min,
        is_real: true,
        ecosystem_uuid: ecosystem_uuid
      }
    else
      {
        minimum: 0,
        most_likely: 0.5,
        maximum: 1,
        is_real: false,
        ecosystem_uuid: ecosystem_uuid
      }
    end
  end
end
