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

  # Adds the given ecosystems to Biglearn
  # Request is a hash containing the following key: :ecosystem
  def create_ecosystem(request)
    { created_ecosystem_uuid: request[:ecosystem].try(:uuid) }
  end

  # Prepares Biglearn for course ecosystem updates
  # Request is a hash containing the following keys: :course and :ecosystem
  def prepare_course_ecosystem(request)
    { prepare_status: :accepted }
  end

  # Finalizes a course ecosystem update in Biglearn,
  # causing it to stop computing CLUes for the old one
  # Requests are hashes containing the following keys: :request_uuid and :preparation_uuid
  def update_course_ecosystems(requests)
    requests.map do |request|
      {
        request_uuid: request[:request_uuid],
        update_status: :updated_and_ready
      }
    end
  end

  # Updates Course rosters in Biglearn
  # Requests are hashes containing the following key: :course
  def update_rosters(requests)
    requests.map{ |request| request[:course].try(:uuid) }
  end

  # Updates global exercise exclusions
  # Request is a hash containing the following key: :exercise_ids
  def update_global_exercise_exclusions(request)
    { updated_exercise_ids: request[:exercise_ids] }
  end

  # Updates exercise exclusions for the given courses
  # Requests are hashes containing the following key: :course
  def update_course_exercise_exclusions(request)
    { updated_course_uuid: request[:course].try(:uuid) }
  end

  # Creates or updates a task in Biglearn
  # Requests are hashes containing the following key: :task
  def create_update_assignments(requests)
    requests.map do |request|
      task = request[:task]

      {
        assignment_uuid: task.try(:uuid),
        sequence_number: task.try(:sequence_number)
      }
    end
  end

  # Returns a number of recommended exercises for the given tasks
  # May return less than the given number if there aren't enough exercises
  # Requests are hashes containing the following keys: :task and :max_exercises_to_return
  def fetch_assignment_pes(requests)
    requests.map do |request|
      {
        assignment_uuid: request[:task].try(:uuid),
        exercise_uuids: [],
        assignment_status: :assignment_ready
      }
    end
  end

  # Returns the CLUes for the given book containers and students
  # Requests are hashes containing the following keys: :book_container and :student
  def fetch_student_clues(requests)
    requests.map do |request|
      {
        request_uuid: request[:request_uuid],
        clue_data: random_clue,
        clue_status: :clue_ready
      }
    end
  end

  # Returns the CLUes for the given book containers and periods
  # Requests are hashes containing the following keys: :book_container and :period
  def fetch_teacher_clues(requests)
    requests.map do |request|
      {
        request_uuid: request[:request_uuid],
        clue_data: random_clue,
        clue_status: :clue_ready
      }
    end
  end

  protected

  def random_clue
    aggregate = rand(0.0..1.0)
    confidence_left  = [aggregate - 0.1, 0.0].max
    confidence_right = [aggregate + 0.1, 1.0].min
    level = aggregate >= 0.8 ? 'high' : (aggregate >= 0.3 ? 'medium' : 'low')
    confidence = ['good', 'bad'].sample
    samples = 7
    threshold = 'above'
    unique_learner_count = 1

    {
      value: aggregate,
      value_interpretation: level,
      confidence_interval: [
        confidence_left,
        confidence_right
      ],
      confidence_interval_interpretation: confidence,
      sample_size: samples,
      sample_size_interpretation: threshold,
      unique_learner_count: unique_learner_count
    }
  end

end
