class OpenStax::Biglearn::Api::FakeClient

  attr_reader :store

  def initialize(biglearn_configuration)
    @store = biglearn_configuration.fake_store
  end

  def reset!
    store.clear
  end

  def name
    :fake
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
    { prepare_status: :accepted }
  end

  # Finalizes course ecosystem updates in Biglearn,
  # causing it to stop computing CLUes for the old one
  # Ignored in the FakeClient
  def update_course_ecosystems(requests)
    requests.map do |request|
      {
        request_uuid: request[:request_uuid],
        update_status: :updated_and_ready
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

  # Ignored in the FakeClient
  def update_global_exercise_exclusions(request)
    { updated_exercise_ids: request[:exercise_ids] }
  end

  # Ignored in the FakeClient
  def update_course_exercise_exclusions(request)
    { updated_course_uuid: request[:course].uuid }
  end

  # Creates or updates tasks in Biglearn
  # In FakeClient, stores the (correct) list of PEs for the task for later use
  def create_update_assignments(requests)
    task_plans = requests.map{ |request| request[:task].task_plan }

    # The following code mimics GetHistory to get the core pages for each task
    homework_exercise_id_to_task_plans_map = {}
    reading_page_id_to_task_plans_map = {}

    # Collect all exercise and page ids first
    task_plans.each do |task_plan|
      task_plan_type = task_plan.try!(:type) || 'nil'

      case task_plan_type
      when 'homework'
        exercise_ids = (task_plan.settings['exercise_ids'] || []).compact.map(&:to_i)
        exercise_ids.each do |exercise_id|
          homework_exercise_id_to_task_plans_map[exercise_id] ||= []
          homework_exercise_id_to_task_plans_map[exercise_id] << task_plan
        end
      when 'reading', 'practice'
        page_ids = (task_plan.settings['page_ids'] || []).compact.map(&:to_i).uniq

        page_ids.each do |page_id|
          reading_page_id_to_task_plans_map[page_id] ||= []
          reading_page_id_to_task_plans_map[page_id] << task_plan
        end
      else
        Rails.logger.warn{ "Biglearn FakeClient ignoring unsupported #{task_plan_type} task_plan" }
      end
    end

    homework_exercise_ids = homework_exercise_id_to_task_plans_map.keys.flatten
    reading_page_ids = reading_page_id_to_task_plans_map.keys.flatten

    # Do some queries to get the dynamic exercises for each assignment type
    task_plan_to_pe_ids_map = {}

    Content::Models::Exercise.joins(page: :homework_dynamic_pool)
                             .where(id: homework_exercise_ids)
                             .select([:id, Content::Models::Pool.arel_table[:content_exercise_ids]])
                             .find_each do |exercise|
      task_plans = homework_exercise_id_to_task_plans_map[exercise.id]

      task_plans.each do |task_plan|
        task_plan_to_pe_ids_map[task_plan] ||= []
        task_plan_to_pe_ids_map[task_plan] += JSON.parse(exercise.content_exercise_ids)
      end
    end

    Content::Models::Page.joins(:reading_dynamic_pool)
                         .where(id: reading_page_ids)
                         .select([:id, Content::Models::Pool.arel_table[:content_exercise_ids]])
                         .each do |page|
      task_plans = reading_page_id_to_task_plans_map[page.id]

      task_plans.each do |task_plan|
        task_plan_to_pe_ids_map[task_plan] ||= []
        task_plan_to_pe_ids_map[task_plan] += JSON.parse(page.content_exercise_ids)
      end
    end

    all_pe_ids = task_plan_to_pe_ids_map.values.flatten

    # Get the uuids for each dynamic exercise id
    pe_id_to_pe_uuid_map = Content::Models::Exercise.where(id: all_pe_ids)
                                                    .pluck(:id, :tutor_uuid).to_h

    task_plan_to_pe_uuids_map = {}
    task_plan_to_pe_ids_map.each do |task_plan, pe_ids|
      task_plan_to_pe_uuids_map[task_plan] = []

      pe_ids.each do |pe_id|
        task_plan_to_pe_uuids_map[task_plan] << pe_id_to_pe_uuid_map[pe_id]
      end
    end

    requests.map do |request|
      task = request[:task]
      task_key = "tasks/#{task.uuid}/pe_uuids"
      exercise_uuids = task_plan_to_pe_uuids_map[task.task_plan] || []

      store.write task_key, exercise_uuids.to_json

      {
        request_uuid: request[:request_uuid],
        assignment_uuid: task.uuid,
        sequence_number: task.sequence_number
      }
    end
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
      task_key = request_task_keys_map[request]
      all_exercise_uuids_json = exercise_uuids_map[task_key]

      if all_exercise_uuids_json.nil?
        {
          request_uuid: request[:request_uuid],
          assignment_uuid: request[:task].uuid,
          exercise_uuids: [],
          assignment_status: :assignment_unknown
        }
      else
        all_exercise_uuids = JSON.parse all_exercise_uuids_json

        {
          request_uuid: request[:request_uuid],
          assignment_uuid: request[:task].uuid,
          exercise_uuids: all_exercise_uuids.sample(request[:max_exercises_to_return]),
          assignment_status: :assignment_ready
        }
      end
    end
  end

  # Returns a number of recommended spaced practice exercises for the given tasks
  # NotYetImplemented in FakeClient (always returns empty result)
  def fetch_assignment_spes(requests)
    requests.map do |request|
      {
        request_uuid: request[:request_uuid],
        assignment_uuid: request[:task].uuid,
        exercise_uuids: [],
        assignment_status: :assignment_ready
      }
    end
  end

  # Returns a number of recommended personalized exercises for the student's worst topics
  # NotYetImplemented in FakeClient (always returns empty result)
  def fetch_practice_worst_areas_pes(requests)
    requests.map do |request|
      {
        request_uuid: request[:request_uuid],
        student_uuid: request[:student].uuid,
        exercise_uuids: [],
        assignment_status: :assignment_ready
      }
    end
  end

  # Returns the CLUes for the given book containers and students (for students)
  # Always returns randomized CLUes in the FakeClient
  def fetch_student_clues(requests)
    requests.map do |request|
      {
        request_uuid: request[:request_uuid],
        clue_data: random_clue,
        clue_status: :clue_ready
      }
    end
  end

  # Returns the CLUes for the given book containers and periods (for teachers)
  # Always returns randomized CLUes in the FakeClient
  def fetch_teacher_clues(requests)
    requests.map do |request|
      {
        request_uuid: request[:request_uuid],
        clue_data: random_clue,
        clue_status: :clue_ready
      }
    end
  end

  def random_clue(options = {})
    options[:value] ||= rand(0.0..1.0)
    options[:value_interpretation] ||= options[:value] >= 0.8 ?
                                         :high : (options[:value] >= 0.3 ? :medium : :low)
    options[:confidence_interval_left]  ||= [options[:value] - 0.1, 0.0].max
    options[:confidence_interval_right] ||= [options[:value] + 0.1, 1.0].min
    options[:confidence_interval_interpretation] = [:good, :bad].sample
    options[:sample_size] = 7
    options[:sample_size_interpretation] = :above
    options[:unique_learner_count] = 1

    {
      value: options[:value],
      value_interpretation: options[:value_interpretation],
      confidence_interval: [
        options[:confidence_interval_left],
        options[:confidence_interval_right]
      ],
      confidence_interval_interpretation: options[:confidence_interval_interpretation],
      sample_size: options[:sample_size],
      sample_size_interpretation: options[:sample_size_interpretation],
      unique_learner_count: options[:unique_learner_count]
    }
  end

end
