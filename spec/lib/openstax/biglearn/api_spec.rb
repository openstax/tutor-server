require 'rails_helper'

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

    it 'can use the fake client or the real client' do
      OpenStax::Biglearn::Api.use_fake_client
      expect(OpenStax::Biglearn::Api.send :client).to be_a(OpenStax::Biglearn::Api::FakeClient)

      OpenStax::Biglearn::Api.use_real_client
      expect(OpenStax::Biglearn::Api.send :client).to be_a(OpenStax::Biglearn::Api::RealClient)

      OpenStax::Biglearn::Api.use_fake_client
      expect(OpenStax::Biglearn::Api.send :client).to be_a(OpenStax::Biglearn::Api::FakeClient)
    end
  end

  context '#default_client_name' do
    it 'returns whatever is in the settings and caches it until the end of the request' do
      allow(Settings::Biglearn).to receive(:client) { 'blah' }
      expect(described_class.default_client_name).to eq 'blah'
      allow(Settings::Biglearn).to receive(:client) { :fake }
      expect(described_class.default_client_name).to eq 'blah'

      RequestStore.clear!

      expect(described_class.default_client_name).to eq :fake
    end
  end

  context 'api calls' do
    dummy_ecosystem = OpenStruct.new tutor_uuid: SecureRandom.uuid
    dummy_book_container = OpenStruct.new tutor_uuid: SecureRandom.uuid
    dummy_course = OpenStruct.new uuid: SecureRandom.uuid, sequence_number: 21
    dummy_course_container = OpenStruct.new uuid: SecureRandom.uuid
    dummy_task = OpenStruct.new uuid: SecureRandom.uuid, sequence_number: 42
    dummy_student = OpenStruct.new uuid: SecureRandom.uuid
    dummy_exercise_ids = [SecureRandom.uuid, '4', "#{SecureRandom.uuid}@1", '4@2']
    max_exercises_to_return = 5

    [
      [ :create_ecosystem, { ecosystem: dummy_ecosystem } ],
      [ :create_course, { course: dummy_course, ecosystem: dummy_ecosystem } ],
      [ :prepare_course_ecosystem, { course: dummy_course, ecosystem: dummy_ecosystem }, String ],
      [ :update_course_ecosystems, [ { preparation_uuid: SecureRandom.uuid } ], Symbol ],
      [ :update_rosters, [ { course: dummy_course } ], Hash, dummy_course ],
      [ :update_global_exercise_exclusions, { exercise_ids: dummy_exercise_ids } ],
      [ :update_course_exercise_exclusions, { course: dummy_course } ],
      [ :create_update_assignments, [ { task: dummy_task } ], Hash, dummy_task ],
      [ :fetch_assignment_pes,
        [ { task: dummy_task, max_exercises_to_return: max_exercises_to_return } ],
        Content::Exercise ],
      [ :fetch_assignment_spes,
        [ { task: dummy_task, max_exercises_to_return: max_exercises_to_return } ],
        Content::Exercise ],
      [ :fetch_practice_worst_areas_pes,
        [ { student: dummy_student, max_exercises_to_return: max_exercises_to_return } ],
        Content::Exercise ],
      [ :fetch_student_clues,
        [ { book_container: dummy_book_container, student: dummy_student } ] ],
      [ :fetch_teacher_clues,
        [ { book_container: dummy_book_container, course_container: dummy_course_container } ] ]
    ].each do |method, requests, result_class, sequence_number_record|
      it "delegates #{method} to the client implementation" do
        sequence_number = sequence_number_record.sequence_number if sequence_number_record.present?

        expect(OpenStax::Biglearn::Api.client).to receive(method).and_call_original

        result_class ||= Hash

        results = OpenStax::Biglearn::Api.send(method, requests)

        results = results.values if requests.is_a?(Array)

        [results].flatten.each do |result|
          expect(result).to be_a result_class
        end

        expect(sequence_number_record.sequence_number).to(eq(sequence_number + 1)) \
          if sequence_number_record.present?
      end
    end

    it 'converts returned exercise uuids to exercise objects' do
      dummy_exercises = max_exercises_to_return.times.map do
        exercise = FactoryGirl.create :content_exercise
        Content::Exercise.new(strategy: exercise.wrap)
      end
      expect(OpenStax::Biglearn::Api.client).to receive(:fetch_assignment_pes) do |requests|
        requests.map do |request|
          {
            request_uuid: request[:request_uuid],
            exercise_uuids: dummy_exercises.map(&:tutor_uuid)
          }
        end
      end
      expect(Rails.logger).not_to receive(:warn)

      result = nil
      expect do
        result = OpenStax::Biglearn::Api.fetch_assignment_pes(
          task: dummy_task, max_exercises_to_return: max_exercises_to_return
        )
      end.not_to raise_error
      expect(result).to match_array(dummy_exercises)
    end

    it 'errors when client returns more exercises than expected' do
      expect(OpenStax::Biglearn::Api.client).to receive(:fetch_assignment_pes) do |requests|
        requests.map do |request|
          {
            request_uuid: request[:request_uuid],
            exercise_uuids: (max_exercises_to_return + 1).times.map{ SecureRandom.uuid }
          }
        end
      end
      expect(Rails.logger).not_to receive(:warn)

      expect do
        OpenStax::Biglearn::Api.fetch_assignment_pes(
          task: dummy_task, max_exercises_to_return: max_exercises_to_return
        )
      end.to raise_error{ OpenStax::Biglearn::Api::ExercisesError }
    end

    it 'logs a warning when client returns less exercises than expected' do
      dummy_exercises = (max_exercises_to_return - 1).times.map do
        exercise = FactoryGirl.create :content_exercise
        Content::Exercise.new(strategy: exercise.wrap)
      end
      expect(OpenStax::Biglearn::Api.client).to receive(:fetch_assignment_pes) do |requests|
        requests.map do |request|
          {
            request_uuid: request[:request_uuid],
            exercise_uuids: dummy_exercises.map(&:tutor_uuid)
          }
        end
      end
      expect(Rails.logger).to receive(:warn)

      result = nil
      expect do
        result = OpenStax::Biglearn::Api.fetch_assignment_pes(
          task: dummy_task, max_exercises_to_return: max_exercises_to_return
        )
      end.not_to raise_error
      expect(result).to match_array(dummy_exercises)
    end

    it 'errors when client returns exercises not present locally' do
      expect(OpenStax::Biglearn::Api.client).to receive(:fetch_assignment_pes) do |requests|
        requests.map do |request|
          {
            request_uuid: request[:request_uuid],
            exercise_uuids: max_exercises_to_return.times.map{ SecureRandom.uuid }
          }
        end
      end
      expect(Rails.logger).not_to receive(:warn)

      expect do
        OpenStax::Biglearn::Api.fetch_assignment_pes(
          task: dummy_task, max_exercises_to_return: max_exercises_to_return
        )
      end.to raise_error{ OpenStax::Biglearn::Api::ExercisesError }
    end
  end
end
