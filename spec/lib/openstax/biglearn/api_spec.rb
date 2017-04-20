require 'rails_helper'
require 'database_cleaner'

RSpec.describe OpenStax::Biglearn::Api, type: :external do
  before(:each) { RequestStore.clear! }
  after(:all)   { RequestStore.clear! }

  context 'configuration' do
    it 'can be configured' do
      configuration = OpenStax::Biglearn::Api.configuration
      expect(configuration).to be_a(OpenStax::Biglearn::Api::Configuration)

      OpenStax::Biglearn::Api.configure do |config|
        expect(config).to eq configuration
      end
    end
  end

  context '#default_client_name' do
    it 'returns whatever is in the settings and caches it until the end of the request' do
      begin
        allow(Settings::Biglearn).to receive(:client) { 'blah' }
        expect(described_class.default_client_name).to eq :blah

        allow(Settings::Biglearn).to receive(:client) { 'fake' }
        expect(described_class.default_client_name).to eq :blah

        RequestStore.clear!

        expect(described_class.default_client_name).to eq :fake
      ensure
        RequestStore.clear!
      end
    end
  end

  context 'api calls' do
    before(:all) do
      DatabaseCleaner.start

      task_plan = FactoryGirl.create :tasked_task_plan
      @ecosystem = task_plan.ecosystem
      @page = @ecosystem.pages.first
      @exercises = @page.exercises
      @course = task_plan.owner
      @task = task_plan.tasks.first
      @tasked_exercise = @task.tasked_exercises.first
      tasking = @task.taskings.first
      @period = tasking.period
      @student = tasking.role.student
    end

    after(:all) { DatabaseCleaner.clean }

    let(:max_num_exercises) { 5 }

    context 'with default perform_later' do
      [
        [
          :create_ecosystem,
          -> { { ecosystem: @ecosystem.tap{ |eco| eco.update_attribute :sequence_number, 0 } } },
          OpenStax::Biglearn::Api::Job,
          -> { @ecosystem },
          1
        ],
        [
          :create_course,
          -> { { course: @course.tap{ |course| course.update_attribute :sequence_number, 0 },
                 ecosystem: @ecosystem } },
          OpenStax::Biglearn::Api::Job,
          -> { @course },
          1
        ],
        [
          :prepare_course_ecosystem,
          -> { { course: @course.reload, ecosystem: @ecosystem.reload } },
          Hash,
          -> { @course },
          1
        ],
        [
          :update_course_ecosystems,
          -> { [ { course: @course.reload, preparation_uuid: SecureRandom.uuid } ] },
          OpenStax::Biglearn::Api::Job,
          -> { @course },
          1
        ],
        [
          :update_rosters,
          -> { [ { course: @course.reload } ] },
          OpenStax::Biglearn::Api::Job,
          -> { @course },
          1
        ],
        [
          :update_globally_excluded_exercises,
          -> { { course: @course.reload } },
          OpenStax::Biglearn::Api::Job,
          -> { @course },
          1
        ],
        [
          :update_course_excluded_exercises,
          -> { { course: @course.reload } },
          OpenStax::Biglearn::Api::Job,
          -> { @course },
          1
        ],
        [
          :update_course_active_dates,
          -> { { course: @course.reload } },
          OpenStax::Biglearn::Api::Job,
          -> { @course },
          1
        ],
        [
          :create_update_assignments,
          -> { [ { course: @course.reload, task: @task.reload } ] },
          OpenStax::Biglearn::Api::Job,
          -> { @course },
          1
        ],
        [
          :record_responses,
          -> { [ { course: @course.reload, tasked_exercise: @tasked_exercise.reload } ] },
          OpenStax::Biglearn::Api::Job,
          -> { @course },
          1
        ],
        [
          :fetch_assignment_pes,
          -> { [ { task: @task.reload, max_num_exercises: max_num_exercises } ] },
          Content::Exercise,
          -> { @course },
          0
        ],
        [
          :fetch_assignment_spes,
          -> { [ { task: @task.reload, max_num_exercises: max_num_exercises } ] },
          Content::Exercise,
          -> { @course },
          0
        ],
        [
          :fetch_practice_worst_areas_exercises,
          -> { [ { student: @student.reload, max_num_exercises: max_num_exercises } ] },
          Content::Exercise,
          -> { @course },
          0
        ],
        [
          :fetch_student_clues,
          -> { [ { book_container: @page.reload, student: @student.reload } ] },
          Hash,
          -> { @course },
          0
        ],
        [
          :fetch_teacher_clues,
          -> { [ { book_container: @page.reload, course_container: @period.reload } ] },
          Hash,
          -> { @course },
          0
        ]
      ].each do |method, requests_proc, result_class, sequence_number_record_proc, increment|
        it "delegates #{method} to the client implementation and returns a job or response" do
          requests = instance_exec &requests_proc
          sequence_number_record = instance_exec &sequence_number_record_proc

          sequence_number = sequence_number_record.sequence_number \
            if sequence_number_record.present?

          expect(OpenStax::Biglearn::Api.client).to receive(method).and_call_original

          results = OpenStax::Biglearn::Api.send(method, requests)

          results = results.values if requests.is_a?(Array) && results.is_a?(Hash)

          [results].flatten.each { |result| expect(result).to be_a result_class }

          expect(sequence_number_record.sequence_number).to(eq(sequence_number + increment)) \
            if sequence_number_record.present?
        end
      end
    end

    context 'with perform_later: false' do
      [
        [
          :create_ecosystem,
          -> { { ecosystem: @ecosystem.tap{ |eco| eco.update_attribute :sequence_number, 0 } } },
          Hash,
          -> { @ecosystem },
          1
        ],
        [
          :create_course,
          -> { { course: @course.tap{ |course| course.update_attribute :sequence_number, 0 },
                 ecosystem: @ecosystem } },
          Hash,
          -> { @course },
          1
        ],
        [
          :prepare_course_ecosystem,
          -> { { course: @course.reload, ecosystem: @ecosystem.reload } },
          Hash,
          -> { @course },
          1
        ],
        [
          :update_course_ecosystems,
          -> { [ { course: @course.reload, preparation_uuid: SecureRandom.uuid } ] },
          Hash,
          -> { @course },
          1
        ],
        [
          :update_rosters,
          -> { [ { course: @course.reload } ] },
          Hash,
          -> { @course },
          1
        ],
        [
          :update_globally_excluded_exercises,
          -> { { course: @course.reload } },
          Hash,
          -> { @course },
          1
        ],
        [
          :update_course_excluded_exercises,
          -> { { course: @course.reload } },
          Hash,
          -> { @course },
          1
        ],
        [
          :update_course_active_dates,
          -> { { course: @course.reload } },
          Hash,
          -> { @course },
          1
        ],
        [
          :create_update_assignments,
          -> { [ { course: @course.reload, task: @task.reload } ] },
          Hash,
          -> { @course },
          1
        ],
        [
          :record_responses,
          -> { [ { course: @course.reload, tasked_exercise: @tasked_exercise.reload } ] },
          Hash,
          -> { @course },
          1
        ]
      ].each do |method, requests_proc, result_class, sequence_number_record_proc, increment|
        it "delegates #{method} to the client implementation and returns the response" do
          requests = instance_exec &requests_proc
          sequence_number_record = instance_exec &sequence_number_record_proc

          sequence_number = sequence_number_record.sequence_number \
            if sequence_number_record.present?

          expect(OpenStax::Biglearn::Api.client).to receive(method).and_call_original

          results = OpenStax::Biglearn::Api.send(method, requests, perform_later: false)

          results = results.values if requests.is_a?(Array)

          [results].flatten.each { |result| expect(result).to be_a result_class }

          expect(sequence_number_record.sequence_number).to(eq(sequence_number + increment)) \
            if sequence_number_record.present?
        end
      end
    end

    it 'converts returned exercise uuids to exercise objects' do
      exercises = @exercises.first(max_num_exercises).map do |exercise|
        Content::Exercise.new strategy: exercise.wrap
      end
      expect(OpenStax::Biglearn::Api.client).to receive(:fetch_assignment_pes) do |requests|
        requests.map do |request|
          {
            request_uuid: request[:request_uuid],
            exercise_uuids: exercises.map(&:uuid)
          }
        end
      end
      expect(Rails.logger).not_to receive(:warn)

      result = nil
      expect do
        result = OpenStax::Biglearn::Api.fetch_assignment_pes(
          task: @task, max_num_exercises: max_num_exercises
        )
      end.not_to raise_error
      expect(result).to match_array(exercises)
    end

    it 'errors when client returns more exercises than expected' do
      expect(OpenStax::Biglearn::Api.client).to receive(:fetch_assignment_pes) do |requests|
        requests.map do |request|
          {
            request_uuid: request[:request_uuid],
            exercise_uuids: (max_num_exercises + 1).times.map{ SecureRandom.uuid }
          }
        end
      end
      expect(Rails.logger).not_to receive(:warn)

      expect do
        OpenStax::Biglearn::Api.fetch_assignment_pes(
          task: @task, max_num_exercises: max_num_exercises
        )
      end.to raise_error{ OpenStax::Biglearn::Api::ExercisesError }
    end

    it 'logs a warning when client returns less exercises than expected' do
      exercises = @exercises.first(max_num_exercises - 1).map do |exercise|
        Content::Exercise.new strategy: exercise.wrap
      end
      expect(OpenStax::Biglearn::Api.client).to receive(:fetch_assignment_pes) do |requests|
        requests.map do |request|
          {
            request_uuid: request[:request_uuid],
            exercise_uuids: exercises.map(&:uuid)
          }
        end
      end
      expect(Rails.logger).to receive(:warn)

      result = nil
      expect do
        result = OpenStax::Biglearn::Api.fetch_assignment_pes(
          task: @task, max_num_exercises: max_num_exercises
        )
      end.not_to raise_error
      expect(result).to match_array(exercises)
    end

    it 'errors when client returns exercises not present locally' do
      expect(OpenStax::Biglearn::Api.client).to receive(:fetch_assignment_pes) do |requests|
        requests.map do |request|
          {
            request_uuid: request[:request_uuid],
            exercise_uuids: max_num_exercises.times.map{ SecureRandom.uuid }
          }
        end
      end
      expect(Rails.logger).not_to receive(:warn)

      expect do
        OpenStax::Biglearn::Api.fetch_assignment_pes(
          task: @task, max_num_exercises: max_num_exercises
        )
      end.to raise_error{ OpenStax::Biglearn::Api::ExercisesError }
    end
  end
end
