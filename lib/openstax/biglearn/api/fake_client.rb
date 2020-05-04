class OpenStax::Biglearn::Api::FakeClient < OpenStax::Biglearn::FakeClient
  NON_RANDOM_K_AGOS = [ 1, 3, 5 ]
  RANDOM_K_AGOS = [ 2, 4 ]

  DEFAULT_NUM_SPES_PER_K_AGO = 1

  MIN_HISTORY_SIZE_FOR_RANDOM_AGO = 5

  # The Z-score of the desired alpha, i.e. the tail of the interval with the desired confidence
  # Reference a Z-score table to adjust this
  # In this case we want a 50% confidence interval (which is pretty bad)
  # So alpha = 0.5 => 1 - alpha/2 = 0.75 => z = 0.68 (from the table)
  CLUE_Z_ALPHA = 0.68
  CLUE_Z_ALPHA_SQUARED = CLUE_Z_ALPHA**2
  CLUE_MIN_NUM_RESPONSES = 3

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
        tasks.map(&:id).each { |task_id| pool_exercises_by_task_id[task_id] = [] }
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

      chosen_exercises = filter_and_choose_exercises(
        exercises: pool_exercises_by_task_id[task.id],
        task: task,
        count: count,
        current_time: current_time
      )

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
  # In the FakeClient returns random SPEs from those allowed by our spaced practice rules
  def fetch_assignment_spes(requests)
    tasks = requests.map { |request| request[:task] }

    ActiveRecord::Associations::Preloader.new.preload(
      tasks, [ :course, taskings: { role: [ { student: :course }, { teacher_student: :course } ] } ]
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
        tasks.map(&:id).each { |task_id| spaced_exercises_by_task_id[task_id] = [] }
        next
      end

      tt = Tasks::Models::Task.arel_table
      tasks.each do |task|
        current_time_ntz = DateTimeUtilities.remove_tz(task.time_zone.now)
        student_history_tasks = Tasks::Models::Task
          .select(:id, :content_ecosystem_id, :core_page_ids)
          .joins(:taskings, :course)
          .where(
            taskings: { entity_role_id: task.taskings.map(&:entity_role_id) },
            task_type: task.task_type
          )
        student_history_tasks = student_history_tasks.where.not(core_steps_completed_at: nil).or(
          student_history_tasks.where(tt[:due_at_ntz].lteq(current_time_ntz))
        ).order(
          Arel.sql(
            <<~ORDER_SQL
              LEAST(
                "tasks_tasks"."core_steps_completed_at",
                TIMEZONE("course_profile_courses"."timezone", "tasks_tasks"."due_at_ntz")
              ) DESC
            ORDER_SQL
          )
        ).preload(:ecosystem).first(6)

        student_history = ([ task ] + student_history_tasks).uniq

        spaced_tasks_num_exercises = get_k_ago_map(
          task: task, include_random_ago: student_history.size > MIN_HISTORY_SIZE_FOR_RANDOM_AGO
        ).map do |k_ago, num_exercises|
          [ student_history[k_ago || RANDOM_K_AGOS.sample] || task, num_exercises ]
        end

        spaced_tasks = spaced_tasks_num_exercises.map(&:first).compact

        ecosystem_map = Content::Map.find_or_create_by(
          from_ecosystems: ([ task.ecosystem ] + spaced_tasks.map(&:ecosystem)).uniq,
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
        chosen_exercises = []
        spaced_tasks_num_exercises.each do |spaced_task, num_exercises|
          exercise_ids = exercise_ids_by_page_id.values_at(
            *spaced_task.core_page_ids
          ).compact.flatten
          exercises = filter_and_choose_exercises(
            exercises: exercises_by_id.values_at(*exercise_ids),
            task: task,
            count: num_exercises,
            additional_excluded_numbers: chosen_exercises.map(&:number),
            current_time: current_time
          )

          remaining -= exercises.size

          chosen_exercises.concat exercises
        end

        if remaining > 0
          # Use personalized exercises if not enough spaced practice exercises available
          exercise_ids = exercise_ids_by_page_id.values_at(*task.core_page_ids).compact.flatten
          chosen_exercises.concat filter_and_choose_exercises(
            exercises: exercises_by_id.values_at(*exercise_ids),
            task: task,
            count: remaining,
            additional_excluded_numbers: chosen_exercises.map(&:number),
            current_time: current_time
          )
        end

        spaced_exercises_by_task_id[task.id] = chosen_exercises
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
      role = student.role
      ecosystem = student.course.ecosystem
      chosen_exercises = []

      unless ecosystem.nil?
        responses_by_page_id = Hash.new { |hash, key| hash[key] = [] }
        Tasks::Models::TaskedExercise.select(
          :id, :answer_ids, :answer_id, :correct_answer_id, :grader_points, :last_graded_at
        ).joins(
          task_step: { task: :taskings }
        ).where(
          task_step: {
            task: { ecosystem: ecosystem, taskings: { entity_role_id: role.id } }
          }
        ).preload(task_step: :task).filter do |tasked_exercise|
          tasked_exercise.feedback_available? current_time: current_time
        end.each do |tasked_exercise|
          responses_by_page_id[tasked_exercise.task_step.content_page_id] <<
            tasked_exercise.is_correct?
        end

        page_ids = responses_by_page_id.sort_by do |_, responses|
          clue = calculate_clue(responses: responses)
          clue[:is_real] ? clue[:most_likely] : 1.5
        end.first(FindOrCreatePracticeTaskRoutine::NUM_EXERCISES).map(&:first)

        pools = Content::Models::Page.where(
          id: page_ids
        ).pluck(:practice_widget_exercise_ids)
        num_pools = pools.size

        if num_pools > 0
          exercises_per_pool, remainder = FindOrCreatePracticeTaskRoutine::NUM_EXERCISES.divmod(
            num_pools
          )
          exercises_by_id = Content::Models::Exercise.select(
            :id, :uuid, :number, :version, :number_of_questions
          ).where(id: pools.flatten).index_by(&:id)
          pools.each_with_index do |pool, index|
            exercises = filter_and_choose_exercises(
              exercises: exercises_by_id.values_at(*pool),
              role: role,
              count: exercises_per_pool + (remainder.to_f/(num_pools - index)).ceil,
              additional_excluded_numbers: chosen_exercises.map(&:number),
              current_time: current_time
            )

            remainder += exercises_per_pool - exercises.size

            chosen_exercises.concat exercises
          end
        end
      end

      {
        request_uuid: request[:request_uuid],
        student_uuid: student.uuid,
        exercise_uuids: chosen_exercises.map(&:uuid),
        student_status: 'student_ready',
        spy_info: {}
      }
    end
  end

  # Returns the CLUes for the given book containers and students (for students)
  # The FakeClient performs the same calculation as biglearn-local-query
  def fetch_student_clues(requests)
    current_time = Time.current

    requests.map do |request|
      student = request.fetch(:student)
      course = student.course
      pages = get_pages course: course, book_container_uuid: request.fetch(:book_container_uuid)
      ecosystem = course.ecosystem

      {
        request_uuid: request[:request_uuid],
        clue_data: calculate_clue_for_students_and_pages(
          students: student, pages: pages, ecosystem: ecosystem, current_time: current_time
        ),
        clue_status: 'clue_ready'
      }
    end
  end

  # Returns the CLUes for the given book containers and periods (for teachers)
  # The FakeClient performs the same calculation as biglearn-local-query
  def fetch_teacher_clues(requests)
    current_time = Time.current

    requests.map do |request|
      period = request.fetch(:course_container)
      course = period.course
      pages = get_pages course: course, book_container_uuid: request.fetch(:book_container_uuid)
      ecosystem = course.ecosystem

      {
        request_uuid: request[:request_uuid],
        clue_data: calculate_clue_for_students_and_pages(
          students: period.students, pages: pages, ecosystem: ecosystem, current_time: current_time
        ),
        clue_status: 'clue_ready'
      }
    end
  end

  protected

  def filter_and_choose_exercises(
    exercises:,
    task: nil,
    role: nil,
    count:,
    additional_excluded_numbers: [],
    current_time: Time.current
  )
    unless task.nil?
      # Always exclude all exercises already assigned to the current task
      excluded_exercise_ids = task.exercise_steps(preload_taskeds: true)
                                  .map(&:tasked)
                                  .map(&:content_exercise_id)

      additional_excluded_numbers += Content::Models::Exercise.where(
        id: excluded_exercise_ids
      ).pluck(:number)
    end

    outs = FilterExcludedExercises.call(
      exercises: exercises,
      task: task,
      role: role,
      additional_excluded_numbers: additional_excluded_numbers,
      current_time: current_time
    ).outputs

    ChooseExercises[
      exercises: outs.exercises,
      count: count,
      already_assigned_exercise_numbers: outs.already_assigned_exercise_numbers
    ]
  end

  def get_pages(course:, book_container_uuid:)
    course.ecosystems.each do |ecosystem|
      ecosystem.books.each do |book|
        toc = book.as_toc
        return toc.pages if toc.unmapped_tutor_uuids.include? book_container_uuid

        # No need to check the units, since we don't currently request unit CLUes
        toc.chapters.each do |chapter|
          return chapter.pages if chapter.unmapped_tutor_uuids.include? book_container_uuid

          chapter.pages.each do |page|
            return [ page ] if page.unmapped_tutor_uuids.include? book_container_uuid
          end
        end
      end
    end

    []
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

  def calculate_clue(responses:, ecosystem: nil)
    num_responses = responses.size

    clue = if num_responses >= CLUE_MIN_NUM_RESPONSES
      num_correct = responses.count { |bool| bool }

      # Agresti-Coull method of statistical inference for the binomial distribution

      # n_hat is the modified number of trials
      n_hat = num_responses + CLUE_Z_ALPHA_SQUARED
      # p_hat is the modified estimate of the probability of success
      p_hat = (num_correct + 0.5 * CLUE_Z_ALPHA_SQUARED)/n_hat

      # Agresti-Coull confidence interval
      interval_delta = CLUE_Z_ALPHA * Math.sqrt(p_hat*(1.0 - p_hat)/n_hat)

      # The Agresti-Coull confidence interval can apparently go outside [0, 1], so we fix that
      {
        minimum: [p_hat - interval_delta, 0.0].max,
        most_likely: p_hat,
        maximum: [p_hat + interval_delta, 1.0].min,
        is_real: true
      }
    else
      {
        minimum: 0.0,
        most_likely: 0.5,
        maximum: 1.0,
        is_real: false
      }
    end

    ecosystem.nil? ? clue : clue.merge(ecosystem_uuid: ecosystem.tutor_uuid)
  end

  def calculate_clue_for_students_and_pages(
    students:, pages:, ecosystem:, current_time: Time.current
  )
    students = [ students ].flatten
    role_ids = students.map(&:entity_role_id)
    page_ids = [ pages ].flatten.map(&:id)
    responses = Tasks::Models::TaskedExercise.select(
      :id, :answer_ids, :answer_id, :correct_answer_id, :grader_points, :last_graded_at
    ).joins(
      task_step: { task: :taskings }
    ).where(
      task_step: { content_page_id: page_ids, task: { taskings: { entity_role_id: role_ids } } }
    ).preload(task_step: :task).filter do |tasked_exercise|
      tasked_exercise.feedback_available? current_time: current_time
    end.map(&:is_correct?)

    calculate_clue responses: responses, ecosystem: ecosystem
  end
end
