class OpenStax::Biglearn::Api::FakeClient < OpenStax::Biglearn::FakeClient
  CLUE_MIN_NUM_RESPONSES = 3 # Must be 2 or more to prevent division by 0
  CLUE_Z_ALPHA = 0.68
  CLUE_Z_ALPHA_SQUARED = CLUE_Z_ALPHA**2

  PRACTICE_WORST_NUM_EXERCISES = 5

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
      exercises_by_id = Content::Models::Exercise.select(:id, :uuid, :number, :version).where(
        id: exercise_ids_by_page_id.values.flatten
      ).index_by(&:id)

      page_ids_by_task_id.each do |task_id, page_ids|
        exercise_ids = exercise_ids_by_page_id.values_at(*page_ids).flatten
        pool_exercises_by_task_id[task_id] = exercises_by_id.values_at(*exercise_ids).compact
      end
    end

    current_time = Time.current
    requests.map do |request|
      task = request[:task]
      count = request.fetch(:max_num_exercises) { task.practice? ? 5 : 3 }
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
      exercises_by_id = Content::Models::Exercise.select(:id, :uuid, :number, :version).where(
        id: exercise_ids_by_page_id.values.flatten
      ).index_by(&:id)

      page_ids_by_task_id.each do |task_id, page_ids|
        exercise_ids = exercise_ids_by_page_id.values_at(*page_ids).flatten
        pool_exercises_by_task_id[task_id] = exercises_by_id.values_at(*exercise_ids).compact
      end
    end

    current_time = Time.current
    requests.map do |request|
      task = request[:task]
      count = request.fetch(:max_num_exercises) { task.practice? ? 5 : 3 }
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

  # Returns a number of recommended personalized exercises for the student's worst topics
  # The FakeClient returns a random personalized exercise from the student's 5 worst topics
  def fetch_practice_worst_areas_exercises(requests)
    current_time = Time.current

    requests.map do |request|
      student = request.fetch(:student)
      role = student.role
      ecosystem = student.course.ecosystem
      exercises = []

      unless ecosystem.nil?
        responses_by_page_id = Hash.new { |hash, key| hash[key] = [] }
        Tasks::Models::TaskedExercise.select(:id, :answer_id, :correct_answer_id).joins(
          task_step: { task: :taskings }
        ).where(
          task_step: {
            task: { ecosystem: ecosystem, taskings: { entity_role_id: role.id } }
          }
        ).preload(task_step: :task).filter do |tasked_exercise|
          tasked_exercise.task_step.task.feedback_available?(current_time: current_time)
        end.each do |tasked_exercise|
          responses_by_page_id[tasked_exercise.task_step.content_page_id] <<
            tasked_exercise.is_correct?
        end

        page_ids = responses_by_page_id.sort_by do |_, responses|
          clue = calculate_clue(responses: responses)
          clue[:is_real] ? clue[:most_likely] : 1.5
        end.first(PRACTICE_WORST_NUM_EXERCISES).map(&:first)

        pools = Content::Models::Page.where(
          id: page_ids
        ).pluck(:practice_widget_exercise_ids)
        num_pools = pools.size

        if num_pools > 0
          exercises_per_pool, remainder = PRACTICE_WORST_NUM_EXERCISES.divmod(num_pools)
          exercises_by_id = Content::Models::Exercise.select(:id, :uuid, :number, :version).where(
            id: pools.flatten
          ).index_by(&:id)
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

  def calculate_clue(responses:, ecosystem: nil)
    num_responses = responses.size

    clue = if num_responses >= CLUE_MIN_NUM_RESPONSES
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
        is_real: true
      }
    else
      {
        minimum: 0,
        most_likely: 0.5,
        maximum: 1,
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
    responses = Tasks::Models::TaskedExercise.select(:id, :answer_id, :correct_answer_id).joins(
      task_step: { task: :taskings }
    ).where(
      task_step: { content_page_id: page_ids, task: { taskings: { entity_role_id: role_ids } } }
    ).preload(task_step: :task).filter do |tasked_exercise|
      tasked_exercise.task_step.task.feedback_available?(current_time: current_time)
    end.map(&:is_correct?)

    calculate_clue responses: responses, ecosystem: ecosystem
  end
end
