require 'rails_helper'

RSpec.shared_examples 'a biglearn scheduler client' do
  let(:configuration) { OpenStax::Biglearn::Scheduler.configuration }
  subject(:client)    { described_class.new(configuration) }

  before(:all) do
    task_plan_1 = FactoryBot.create(:tasked_task_plan)
    @task = task_plan_1.tasks.first
    @student = @task.taskings.first.role.student
    # When re-recording the cassettes, set the task and student uuids
    # to values that exist in biglearn-scheduler
  end

  when_tagged_with_vcr = { vcr: ->(v) { !!v } }

  before(:all, when_tagged_with_vcr) do
    VCR.configure do |config|
      config.ignore_localhost = false
      config.define_cassette_placeholder('<STUDENT UUID>'    ) { @student.uuid }
      config.define_cassette_placeholder('<TASK UUID>'       ) { @task.uuid    }
    end
  end

  after(:all, when_tagged_with_vcr) { VCR.configuration.ignore_localhost = true }

  context '#fetch_algorithm_exercise_calculations' do
    before(:all) do
      @requests = [ { student: @student }, { task: @task }, { student: @student, task: @task } ]
      @request_uuids = @requests.map { SecureRandom.uuid }
    end

    before(:all, when_tagged_with_vcr) do
      VCR.configure do |config|
        @request_uuids.each_with_index do |request_uuid, request_index|
          config.define_cassette_placeholder(
            "<fetch_algorithm_exercise_calculations REQUEST #{request_index + 1} UUID>"
          ) { request_uuid }
        end
      end
    end

    it 'returns the expected response for the request' do
      requests = @requests.each_with_index.map do |request, index|
        request.merge(request_uuid: @request_uuids[index])
      end

      expected_responses = requests.map do |request|
        {
          request_uuid: request[:request_uuid],
          calculations: [
            student_uuid: @student.uuid,
            calculation_uuid: kind_of(String),
            ecosystem_matrix_uuid: kind_of(String),
            algorithm_name: be_in([ 'local_query', 'biglearn_sparfa' ]),
            exercise_uuids: kind_of(Array)
          ]
        }
      end

      actual_responses = client.fetch_algorithm_exercise_calculations requests

      expect(actual_responses).to match_array(expected_responses)
    end
  end
end
