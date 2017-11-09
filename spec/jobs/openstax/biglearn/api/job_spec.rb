require 'rails_helper'

RSpec.describe OpenStax::Biglearn::Api::Job, type: :job do
  subject(:job)  { described_class.new }

  let(:course)   { FactoryBot.create :course_profile_course }

  let(:method)   { :create_course }
  let(:requests) { { course: course } }

  let(:args)     { { method: method, requests: requests } }

  it 'delegates #perform to a new instance of itself' do
    allow(described_class).to receive(:new).and_return(job)
    expect(job).to receive(:perform).with(args)

    described_class.perform(args)
  end

  it 'calls the Biglearn client with the given arguments' do
    expect(OpenStax::Biglearn::Api.client).to receive(method).with(requests)

    job.perform(args)
  end

  context 'with response_status_key and accepted_response_status' do
    it 'raises OpenStax::Biglearn::Api::JobFailed if the status is not accepted' do
      failing_args = args.merge(
        response_status_key: :course_status, accepted_response_status: []
      )

      expect(OpenStax::Biglearn::Api.client).to receive(method).with(requests) do |request|
        {
          request_uuid: request[:request_uuid],
          course_status: 'created'
        }
      end

      expect{ job.perform(failing_args) }.to raise_error(OpenStax::Biglearn::Api::JobFailed)
    end

    it 'does not raise an Exception if the status is accepted' do
      failing_args = args.merge(
        response_status_key: :course_status, accepted_response_status: 'created'
      )

      expect(OpenStax::Biglearn::Api.client).to receive(method).with(requests) do |request|
        {
          request_uuid: request[:request_uuid],
          course_status: 'created'
        }
      end

      expect{ job.perform(failing_args) }.not_to raise_error
    end
  end
end
