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
  # Requests are hashes containing the following keys: :ecosystem
  def create_ecosystems(requests)
    requests.map{ |request| {} }
  end

  # Prepares Biglearn for course ecosystem updates
  # Requests are hashes containing the following keys: :course and :ecosystem
  def prepare_course_ecosystems(requests)
    requests.map{ |request| {} }
  end

  # Finalizes a course ecosystem update in Biglearn,
  # causing it to stop computing CLUes for the old one
  # Requests are hashes containing the following key: :course
  def update_course_ecosystems(requests)
    requests.map{ |request| {} }
  end

  # Updates Course rosters in Biglearn
  # Requests are hashes containing the following key: :course
  def update_rosters(requests)
    requests.map{ |request| {} }
  end

  # Updates global exercise exclusions
  # Request is a hash containing the following key: :exercise_ids
  def update_global_exercise_exclusions(request)
    request = request.first
    [{}]
  end

  # Updates exercise exclusions for the given courses
  # Requests are hashes containing the following key: :course
  def update_course_exercise_exclusions(requests)
    requests.map{ |request| {} }
  end

  # Creates or updates a task in Biglearn
  # Requests are hashes containing the following key: :task
  def create_or_update_assignments(requests)
    requests.map{ |request| {} }
  end

  # Returns a number of recommended exercises for the given tasks
  # May return less than the given number if there aren't enough exercises
  # Requests are hashes containing the following keys: :task and :max_exercises_to_return
  def fetch_assignment_pes(requests)
    requests.map{ |request| [] }
  end

  # Returns a number of recommended exercises for the given students and ecosystems
  # May return less than the given number if there aren't enough exercises
  # Requests are hashes containing the following keys:
  # :student, :ecosystem and max_exercises_to_return
  def fetch_weakest_topics_pes(requests)
    requests.map{ |request| {} }
  end

  # Returns the CLUes for the given book containers and students
  # Requests are hashes containing the following keys: :book_container and :student
  def fetch_learner_clues(requests)
    requests.map{ |request| {} }
  end

  # Returns the CLUes for the given book containers and periods
  # Requests are hashes containing the following keys: :book_container and :period
  def fetch_teacher_clues(requests:)
    client.fetch_teacher_clues(requests: requests)
  end

end
