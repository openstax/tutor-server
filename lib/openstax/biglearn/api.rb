require_relative './api/configuration'
require_relative './api/fake_client'
require_relative './api/real_client'
require_relative './api/local_clue'
require_relative './api/local_query_client'

module OpenStax::Biglearn::Api

  extend Configurable
  extend Configurable::ClientMethods
  extend MonitorMixin

  class << self

    #
    # API Wrappers
    #

    # ecosystem is a Content::Ecosystem or Content::Models::Ecosystem
    # course is an Entity::Course
    # task is a Tasks::Models::Task
    # student is a CourseMembership::Models::Student
    # book_container is a Content::Chapter or Content::Page or one of their models
    # exercise_id is a String containing an Exercise uuid, number or uid
    # period is a CourseMembership::Period or CourseMembership::Models::Period
    # max_exercises_to_return is an integer

    # Adds the given Content::Ecosystems to Biglearn
    def create_ecosystems(ecosystems:)
      #client.create_ecosystems(ecosystems: ecosystems)
    end

    # Prepares Biglearn for Entity::Course ecosystem updates
    # Updates are constructed by matching items in the array with the same index
    def prepare_course_ecosystems(courses:, ecosystems:)
      #client.prepare_course_ecosystems(updates: updates)
    end

    # Finalizes an Entity::Course ecosystem update in Biglearn,
    # causing it to stop computing CLUes for the old one
    def update_course_ecosystems(courses:)
      #client.update_course_ecosystems(courses: courses)
    end

    # Updates Course rosters in Biglearn
    def update_rosters(courses:)
      #client.update_rosters(courses: courses)
    end

    # Updates global exercise exclusions
    def update_global_exercise_exclusions(exercise_ids:)
      #client.update_global_exercise_exclusions(exercise_ids: exercise_ids)
    end

    # Updates exercise exclusions for the given course
    def update_course_exercise_exclusions(course:)
      #client.update_course_exercise_exclusions(course: course)
    end

    # Creates or updates a Tasks::Models::Task in Biglearn
    def create_or_update_assignments(tasks:)
      #client.create_or_update_assignments(tasks: tasks)
    end

    # Returns a number of recommended exercises for the given tasks
    # May return less than the given number if there aren't enough exercises
    def fetch_assignment_pes(tasks:, max_exercises_to_return:)
      #client.fetch_assignment_pes(tasks: tasks, max_exercises_to_return: max_exercises_to_return)
      []
    end

    # Returns a number of recommended exercises for the given students and book containers
    # One clue is returned for each student, book_container pair
    # Book container is a Content::Chapter or Content::Page
    # May return less than the given number if there aren't enough exercises
    def fetch_topic_pes(students:, book_containers:, max_exercises_to_return:)
      #client.fetch_topic_pes(students: students, book_containers: book_containers,
      #                       max_exercises_to_return: max_exercises_to_return)
      []
    end

    # Returns a number of recommended exercises for the given students and ecosystems
    # May return less than the given number if there aren't enough exercises
    def fetch_weakest_topics_pes(students:, ecosystems:, max_exercises_to_return:)
      #client.fetch_weakest_topics_pes(students: students, ecosystems: ecosystems,
      #                                max_exercises_to_return: max_exercises_to_return)
      []
    end

    # Returns the CLUes for the given book containers and students
    def fetch_learner_clues(book_containers:, students:)
      #client.fetch_learner_clues(book_containers: book_containers, students: students)
      []
    end

    # Returns the CLUes for the given book containers and periods
    def fetch_teacher_clues(book_containers:, periods:)
      #client.fetch_teacher_clues(book_containers: book_containers, periods: periods)
      []
    end

    #
    # Configuration
    #

    # Accessor for the fake client, which has some extra fake methods on it
    def new_fake_client
      new_client_call { FakeClient.new(configuration) }
    end

    def new_real_client
      new_client_call { RealClient.new(configuration) }
    end

    def new_local_query_client_with_fake
      new_client_call { LocalQueryClient.new(new_fake_client) }
    end

    def new_local_query_client_with_real
      new_client_call { LocalQueryClient.new(new_real_client) }
    end

    def use_real_client
      use_client_named(:real)
    end

    def use_fake_client
      use_client_named(:fake)
    end

    def use_client_named(client_name)
      RequestStore.store[:biglearn_v1_forced_client_in_use] = true
      self.client = new_client(client_name)
    end

    def default_client_name
      # The default Biglearn client is set via an admin console setting.  The
      # default value for this setting is environment-specific in config/initializers/
      # 02-settings.rb. Developers will need to use the admin console to change
      # the setting if they want during development.  During testing, devs can
      # use the `use_fake_client`, `use_real_client`, and `use_client_named`
      # methods.

      # We only read this setting once per request to prevent it from changing mid-request
      RequestStore.store[:biglearn_v1_default_client_name] ||= Settings::Biglearn.client
    end

    alias :threadsafe_client :client

    def client
      # We normally keep a cached version of the client in use.  If a caller
      # (normally a spec) has said to use a specific client, we don't want to
      # change the client. However if this is not the case and the client's
      # name no longer matches the admin DB setting, change it out.

      synchronize do
        if threadsafe_client.nil? ||
           (!RequestStore.store[:biglearn_v1_forced_client_in_use] &&
            threadsafe_client.name != default_client_name)
          self.client = new_client
          save_static_client!
        end
      end

      threadsafe_client
    end

    protected

    def new_configuration
      OpenStax::Biglearn::Api::Configuration.new
    end

    def new_client(name = default_client_name)
      case name
      when :local_query_with_fake
        new_local_query_client_with_fake
      when :local_query_with_real
        new_local_query_client_with_real
      when :real
        new_real_client
      when :fake
        new_fake_client
      else
        raise "Invalid client name (#{name}); don't know which Biglearn client to make"
      end
    end

    def new_client_call
      begin
        yield
      rescue StandardError => e
        raise "Biglearn client initialization error: #{e.message}"
      end
    end

  end

end
