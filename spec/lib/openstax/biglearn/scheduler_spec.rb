require 'rails_helper'
require 'database_cleaner'

RSpec.describe OpenStax::Biglearn::Scheduler, type: :external do
  before(:each) { RequestStore.clear! }
  after(:all)   { RequestStore.clear! }

  context 'configuration' do
    it 'can be configured' do
      configuration = described_class.configuration
      expect(configuration).to be_a described_class::Configuration

      described_class.configure { |config| expect(config).to eq configuration }
    end
  end

  context 'api calls' do
    before(:all) do
      DatabaseCleaner.start

      reading_task_plan = FactoryBot.create :tasked_task_plan, number_of_students: 1
      @task = reading_task_plan.tasks.first
      @student = @task.taskings.first.role.student
      @exercises = @task.ecosystem.pages.first.exercises
    end

    after(:all) { DatabaseCleaner.clean }

    it "delegates fetch_algorithm_exercise_calculations to the client and returns a response" do
      requests = [ { student: @student }, { task: @task }, { student: @student, task: @task } ]

      expect(described_class.client).to receive(
        :fetch_algorithm_exercise_calculations
      ).and_call_original

      results = described_class.fetch_algorithm_exercise_calculations requests

      results = results.values if requests.is_a?(Array) && results.is_a?(Hash)

      [results].flatten.each { |result| expect(result).to be_a Hash }
    end

    it 'converts returned exercise uuids to exercise objects, preserving their order' do
      expect(@exercises).not_to be_empty
      exercises = @exercises.map do |exercise|
        Content::Exercise.new strategy: exercise.wrap
      end
      expect(Rails.logger).not_to receive(:warn)

      expect(described_class.client).to(
        receive(:fetch_algorithm_exercise_calculations) do |requests|
          requests.map do |request|
            {
              request_uuid: request[:request_uuid],
              student_uuid: SecureRandom.uuid,
              calculation_uuid: SecureRandom.uuid,
              ecosystem_matrix_uuid: SecureRandom.uuid,
              algorithm_name: [ 'local_query', 'biglearn_sparfa' ].sample,
              exercise_uuids: exercises.map(&:uuid)
            }
          end
        end.once
      )

      results = described_class.fetch_algorithm_exercise_calculations [ { task: @task } ]
      results.values.each { |result| expect(result[:exercises]).to eq exercises }
    end

    it 'errors when client returns exercises not present locally' do
      expect(described_class.client).to(
        receive(:fetch_algorithm_exercise_calculations) do |requests|
          requests.map do |request|
            {
              request_uuid: request[:request_uuid],
              exercise_uuids: max_num_exercises.times.map { SecureRandom.uuid },
              assignment_status: 'assignment_ready'
            }
          end
        end
      )
      expect(Rails.logger).not_to receive(:warn)

      expect do
        described_class.fetch_algorithm_exercise_calculations [ { task: @task } ]
      end.to raise_error { OpenStax::Biglearn::ExercisesError }
    end
  end
end
