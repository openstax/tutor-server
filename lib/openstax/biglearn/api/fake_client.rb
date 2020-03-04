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
  def create_update_assignments(requests)
    requests.map do |request|
      { request_uuid: request[:request_uuid], updated_assignment_uuid: request[:task].uuid }
    end
  end

  # Records the given student responses
  def record_responses(requests)
    requests.map { |request| request.slice :response_uuid }
  end

  # Returns a number of recommended personalized exercises for the given tasks
  # In the FakeClient, always returns random PEs from the same pages as the task
  def fetch_assignment_pes(requests)
    tasks = requests.map { |request| request[:task] }

    ActiveRecord::Associations::Preloader.new.preload(
      tasks, :task_steps, taskings: { role: [ { student: :course }, { teacher_student: :course } ] }
    )

    pool_exercise_ids_by_task_id = {}
    tasks.group_by(:task_type).each do |task_type, tasks|
      case task_type
      when 'reading', 'homework'
        pool_method = "#{task_type}_dynamic_exercise_ids".to_sym
      when 'chapter_practice', 'page_practice', 'mixed_practice', 'practice_worst_topics'
        pool_method = :practice_widget_exercise_ids
      else
        tasks.map(&:id).each { |task_id| pool_exercise_ids_by_task_id[task_id] = [] }
        next
      end

      page_ids_by_task_id = tasks.map do |task|
        [ task.id, task.task_steps.map(&:content_page_id).uniq ]
      end.to_h
      exercise_ids_by_page_id = Content::Models::Page.where(
        id: page_ids_by_task_id.values.flatten.uniq
      ).pluck(:id, pool_method).to_h
      exercises_by_id = Content::Models::Exercise.select(:id, :uuid, :number).where(
        id: exercise_ids_by_page_id.values.flatten
      ).index_by(&:id)

      page_ids_by_task_id.each do |task_id, page_ids|
        exercise_ids = exercise_ids_by_page_id.values_at(*page_ids).flatten
        pool_exercises_by_task_id[task_id] = exercises_by_id.values_at *exercise_ids
      end
    end

    current_time = Time.current
    requests.map do |request|
      task = request[:task]
      count = request.fetch(:max_num_exercises) { task.practice? ? 5 : 3 }
      request_uuid = request[:request_uuid]

      pool_exercises = pool_exercises_by_task_id[task.id]
      outs = FilterExcludedExercises.call(
        exercises: pool_exercises, task: task, current_time: current_time
      ).outputs
      worked_exercise_numbers = outs.worked_exercise_numbers
      filtered_exercises = outs.exercises
      chosen_exercises = ChooseExercises[
        exercises: outs.exercises,
        count: count,
        worked_exercise_numbers: outs.worked_exercise_numbers
      ]

      {
        request_uuid: request_uuid,
        assignment_uuid: task.uuid,
        exercise_uuids: chosen_exercises.map(&:uuid),
        assignment_status: 'assignment_ready',
        spy_info: {}
      }
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

      {
        request_uuid: request[:request_uuid],
        clue_data: calculate_clue(students: student, ecosystem: student.course.ecosystem),
        clue_status: 'clue_ready'
      }
    end
  end

  # Returns the CLUes for the given book containers and periods (for teachers)
  # The FakeClient performs the same calculation as biglearn-local-query
  def fetch_teacher_clues(requests)
    requests.map do |request|
      period = request.fetch(:course_container)

      {
        request_uuid: request[:request_uuid],
        clue_data: calculate_clue(students: period.students, ecosystem: period.course.ecosystem),
        clue_status: 'clue_ready'
      }
    end
  end

  protected

  def calculate_clue(students:, ecosystem:)
    role_ids = students.map(&:entity_role_id)
    tasked_exercises = Tasks::Models::TaskedExercise.select(:answer_id, :correct_answer_id).joins(
      task_step: { task: :taskings }
    ).where(task_step: { task: { taskings: { entity_role_id: role_ids } } }).to_a
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
        ecosystem_uuid: ecosystem.tutor_uuid
      }
    else
      {
        minimum: 0,
        most_likely: 0.5,
        maximum: 1,
        is_real: false,
        ecosystem_uuid: ecosystem.tutor_uuid
      }
    end
  end
end
