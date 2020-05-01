class OpenStax::Biglearn::Api::FakeClient < OpenStax::Biglearn::FakeClient
  NON_RANDOM_K_AGOS = [ 1, 3, 5 ]
  RANDOM_K_AGOS = [ 2, 4 ]

  DEFAULT_NUM_SPES_PER_K_AGO = 1

  MIN_HISTORY_SIZE_FOR_RANDOM_AGO = 5

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
  # The FakeClient returns random PEs from the same pages as the task
  def fetch_assignment_pes(requests)
    tasks = requests.map { |request| request[:task] }

    ActiveRecord::Associations::Preloader.new.preload(
      tasks, [
        :task_steps, taskings: { role: [ { student: :course }, { teacher_student: :course } ] }
      ]
    )

    pool_exercises_by_task_id = {}
    tasks.group_by(&:task_type).each do |task_type, tasks|
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
      exercises_by_id = Content::Models::Exercise.select(
        :id, :uuid, :number, :version, :number_of_questions
      ).where(id: exercise_ids_by_page_id.values.flatten).index_by(&:id)

      page_ids_by_task_id.each do |task_id, page_ids|
        exercise_ids = exercise_ids_by_page_id.values_at(*page_ids).flatten
        pool_exercises_by_task_id[task_id] = exercises_by_id.values_at(*exercise_ids).compact
      end
    end

    current_time = Time.current
    requests.map do |request|
      task = request[:task]
      count = request.fetch(:max_num_exercises) { task.goal_num_pes }
      request_uuid = request[:request_uuid]

      exercises = filter_and_choose_exercises(
        exercises: pool_exercises_by_task_id[task.id],
        task: task,
        count: count,
        current_time: current_time
      )

      {
        request_uuid: request_uuid,
        assignment_uuid: task.uuid,
        exercise_uuids: exercises.map(&:uuid),
        assignment_status: 'assignment_ready',
        spy_info: {}
      }
    end
  end

  # Returns a number of recommended spaced practice exercises for the given tasks
  # In the FakeClient returns random SPEs from those allowed by our spaced practice rules
  def fetch_assignment_spes(requests)
    tasks = requests.map { |request| request[:task] }

    ActiveRecord::Associations::Preloader.new.preload(
      tasks, [ taskings: { role: [ { student: :course }, { teacher_student: :course } ] } ]
    )

    current_time = Time.current
    spaced_exercises_by_task_id = {}
    tasks.group_by(&:task_type).each do |task_type, tasks|
      case task_type
      when 'reading', 'homework'
        pool_type = "#{task_type}_dynamic".to_sym
      when 'chapter_practice', 'page_practice', 'mixed_practice', 'practice_worst_topics'
        pool_type = :practice_widget
      else
        tasks.map(&:id).each { |task_id| pool_exercise_ids_by_task_id[task_id] = [] }
        next
      end

      tasks.each do |task|
        student_history = (
          [ task ] + Tasks::Models::Task.select(:id, :content_ecosystem_id, :core_page_ids)
          .joins(:taskings)
          .where(
            taskings: { entity_role_id: task.taskings.map(&:entity_role_id) },
            task_type: task.task_type
          )
          .where.not(student_history_at: nil)
          .order(student_history_at: :desc)
          .preload(:ecosystem)
          .first(6)
        ).uniq

        spaced_tasks_num_exercises = get_k_ago_map(
          task: task, include_random_ago: student_history.size > MIN_HISTORY_SIZE_FOR_RANDOM_AGO
        ).map do |k_ago, num_exercises|
          [ student_history[k_ago || RANDOM_K_AGOS.sample] || task, num_exercises ]
        end

        spaced_tasks = spaced_tasks_num_exercises.map(&:first).compact

        ecosystem_map = Content::Map.find_or_create_by(
          from_ecosystems: spaced_tasks.map(&:ecosystem).uniq,
          to_ecosystem: task.ecosystem
        )

        page_ids = (task.core_page_ids + spaced_tasks.flat_map(&:core_page_ids)).uniq
        exercise_ids_by_page_id = ecosystem_map.map_page_ids_to_exercise_ids(
          page_ids: page_ids, pool_type: pool_type
        )
        exercises_by_id = Content::Models::Exercise.select(
          :id, :uuid, :number, :version, :number_of_questions
        ).where(id: exercise_ids_by_page_id.values.flatten).index_by(&:id)

        remaining = spaced_tasks_num_exercises.map(&:second).sum
        spaced_exercises_by_task_id[task.id] =
          spaced_tasks_num_exercises.flat_map do |task, num_exercises|
          exercise_ids = exercise_ids_by_page_id.values_at(*task.core_page_ids).compact.flatten

          filter_and_choose_exercises(
            exercises: exercises_by_id.values_at(*exercise_ids),
            task: task,
            count: num_exercises,
            current_time: current_time
          ).tap { |exercises| remaining -= exercises.size }
        end

        if remaining > 0
          # Use personalized exercises if not enough spaced practice exercises available
          exercise_ids = exercise_ids_by_page_id.values_at(*task.core_page_ids).compact.flatten

          spaced_exercises_by_task_id[task.id] += filter_and_choose_exercises(
            exercises: exercises_by_id.values_at(*exercise_ids),
            task: task,
            count: remaining,
            current_time: current_time
          )
        end
      end
    end

    requests.map do |request|
      task = request[:task]
      count = request.fetch(:max_num_exercises) { task.goal_num_spes }
      request_uuid = request[:request_uuid]

      {
        request_uuid: request_uuid,
        assignment_uuid: task.uuid,
        exercise_uuids: spaced_exercises_by_task_id[task.id].first(count).map(&:uuid),
        assignment_status: 'assignment_ready',
        spy_info: {}
      }
    end
  end

  # Returns a number of recommended personalized exercises for the student's worst topics
  # The FakeClient returns a random personalized exercise from the student's 5 worst topics
  def fetch_practice_worst_areas_exercises(requests)
    current_time = Time.current

    requests.map do |request|
      student = request.fetch(:student)
      ecosystem = student.course.ecosystem
      exercises = []

      unless ecosystem.nil?
        role = student.role
        page_uuids = Cache::RoleBookPart.where(
          role: role, is_page: true
        ).sort_by do |role_book_part|
          role_book_part.clue['is_real'] ? role_book_part.clue['most_likely'] : 1.5
        end.first(FindOrCreatePracticeTaskRoutine::NUM_EXERCISES).map(&:book_part_uuid)

        exercise_ids_by_page_uuid = ecosystem
          .pages
          .where(uuid: page_uuids)
          .pluck(:uuid, :practice_widget_exercise_ids)
          .to_h

        pools = page_uuids.map { |page_uuid| exercise_ids_by_page_uuid[page_uuid] }.reject(&:blank?)
        num_pools = pools.size

        if num_pools > 0
          exercises_per_pool, remainder = FindOrCreatePracticeTaskRoutine::NUM_EXERCISES.divmod(
            num_pools
          )

          exercises_by_id = Content::Models::Exercise.select(
            :id, :uuid, :number, :version, :number_of_questions
          ).where(id: pools.flatten).index_by(&:id)

          pools.each_with_index do |pool, index|
            ex = filter_and_choose_exercises(
              exercises: exercises_by_id.values_at(*pool),
              role: role,
              count: exercises_per_pool + (remainder.to_f/(num_pools - index)).ceil,
              current_time: current_time
            )

            remainder += exercises_per_pool - ex.size

            exercises.concat ex
          end
        end
      end

      {
        request_uuid: request[:request_uuid],
        student_uuid: student.uuid,
        exercise_uuids: exercises.map(&:uuid),
        student_status: 'student_ready',
        spy_info: {}
      }
    end
  end

  # Returns the CLUes for the given book containers and students (for students)
  # The FakeClient performs the same calculation as biglearn-local-query
  def fetch_student_clues(requests)
    current_time = Time.current

    values = requests.map do |request|
      [ request.fetch(:student).entity_role_id, request.fetch(:book_container_uuid) ]
    end
    role_book_part_join_query = <<-JOIN_SQL.strip_heredoc
      INNER JOIN (#{ValuesTable.new(values)}) AS "values" ("role_id", "book_part_uuid")
        ON "cache_role_book_parts"."entity_role_id" = "values"."role_id"
          AND "cache_role_book_parts"."book_part_uuid" = "values"."book_part_uuid"
    JOIN_SQL

    clues_by_role_id_and_book_part_uuid = Hash.new { |hash, key| hash[key] = {} }
    Cache::RoleBookPart.joins(role_book_part_join_query).each do |role_book_part|
      role_id = role_book_part.entity_role_id
      book_part_uuid = role_book_part.book_part_uuid

      clues_by_role_id_and_book_part_uuid[role_id][book_part_uuid] = role_book_part.clue
    end

    requests.map do |request|
      role_id = request.fetch(:student).entity_role_id
      book_part_uuid = request.fetch(:book_container_uuid)
      clue = clues_by_role_id_and_book_part_uuid[role_id][book_part_uuid]

      if clue.nil?
        clue = {
          minimum: 0.0,
          most_likely: 0.5,
          maximum: 1.0,
          is_real: false
        }
        clue_status = 'clue_unready'
      else
        clue_status = 'clue_ready'
      end

      {
        request_uuid: request[:request_uuid],
        clue_data: clue,
        clue_status: clue_status
      }
    end
  end

  # Returns the CLUes for the given book containers and periods (for teachers)
  # The FakeClient performs the same calculation as biglearn-local-query
  def fetch_teacher_clues(requests)
    current_time = Time.current

    values = requests.map do |request|
      [ request.fetch(:course_container).id, request.fetch(:book_container_uuid) ]
    end
    period_book_part_join_query = <<-JOIN_SQL.strip_heredoc
      INNER JOIN (#{ValuesTable.new(values)}) AS "values" ("period_id", "book_part_uuid")
        ON "cache_period_book_parts"."course_membership_period_id" = "values"."period_id"
          AND "cache_period_book_parts"."book_part_uuid" = "values"."book_part_uuid"
    JOIN_SQL

    clues_by_period_id_and_book_part_uuid = Hash.new { |hash, key| hash[key] = {} }
    Cache::PeriodBookPart.joins(period_book_part_join_query).each do |period_book_part|
      period_id = period_book_part.course_membership_period_id
      book_part_uuid = period_book_part.book_part_uuid

      clues_by_period_id_and_book_part_uuid[period_id][book_part_uuid] = period_book_part.clue
    end

    requests.map do |request|
      period_id = request.fetch(:course_container).id
      book_part_uuid = request.fetch(:book_container_uuid)
      clue = clues_by_period_id_and_book_part_uuid[period_id][book_part_uuid]

      if clue.nil?
        clue = {
          minimum: 0.0,
          most_likely: 0.5,
          maximum: 1.0,
          is_real: false
        }
        clue_status = 'clue_unready'
      else
        clue_status = 'clue_ready'
      end

      {
        request_uuid: request[:request_uuid],
        clue_data: clue,
        clue_status: clue_status
      }
    end
  end

  protected

  def filter_and_choose_exercises(
    exercises:, task: nil, role: nil, count:, current_time: Time.current
  )
    outs = FilterExcludedExercises.call(
      exercises: exercises, task: task, role: role, current_time: current_time
    ).outputs

    ChooseExercises[
      exercises: outs.exercises,
      count: count,
      already_assigned_exercise_numbers: outs.already_assigned_exercise_numbers
    ]
  end

  def get_k_ago_map(task:, include_random_ago: false)
    # Entries in the list have the form: [from-this-many-tasks-ago, pick-this-many-exercises]
    num_spes = task.goal_num_spes

    case num_spes
    when Integer
      # Tutor decides
      return [] if num_spes == 0

      # Subtract 1 for random-ago/personalized
      num_spes -= 1
      num_spes_per_k_ago, remainder = num_spes.divmod NON_RANDOM_K_AGOS.size

      [].tap do |k_ago_map|
        NON_RANDOM_K_AGOS.each_with_index do |k_ago, index|
          num_k_ago_spes = index < remainder ? num_spes_per_k_ago + 1 : num_spes_per_k_ago

          k_ago_map << [k_ago, num_k_ago_spes] if num_k_ago_spes > 0
        end

        k_ago_map << [(include_random_ago ? nil : 0), 1]
      end
    when NilClass
      # Biglearn decides
      NON_RANDOM_K_AGOS.map do |k_ago|
        [k_ago, DEFAULT_NUM_SPES_PER_K_AGO]
      end.compact.tap do |k_ago_map|
        k_ago_map << [(include_random_ago ? nil : 0), 1]
      end
    else
      raise ArgumentError, "Invalid assignment num_spes: #{num_spes.inspect}", caller
    end
  end
end
