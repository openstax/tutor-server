require 'rails_helper'

RSpec.describe OpenStax::Biglearn::Api::JobWithSequenceNumber, type: :job do
  subject(:job_with_sequence_number)   { described_class.new }

  let(:course)                         { FactoryGirl.create :course_profile_course }

  let(:method)                         { :create_course }
  let(:request)                        { { course: course } }
  let(:create)                         { true }
  let(:sequence_number_model_key)      { :course }
  let(:sequence_number_model_class)    { CourseProfile::Models::Course }

  let(:args)                           do
    {
      method: method,
      requests: request,
      create: create,
      sequence_number_model_key: sequence_number_model_key,
      sequence_number_model_class: sequence_number_model_class
    }
  end

  let(:request_with_sequence_numbers)  { request.merge sequence_number: 0 }
  let(:job_args)                       do
    { method: method.to_s, requests: request_with_sequence_numbers }
  end

  it 'delegates #perform to a new instance of itself' do
    allow(described_class).to receive(:new).and_return(job_with_sequence_number)
    expect(job_with_sequence_number).to receive(:perform).with(args)

    described_class.perform(args)
  end

  it 'increments the course\'s sequence_number' do
    expect { job_with_sequence_number.perform(args) }.to change { course.sequence_number }.by(1)
  end

  context 'when delay_jobs is true' do
    before { allow(Delayed::Worker).to receive(:delay_jobs).and_return(true) }

    it 'creates a new OpenStax::Biglearn::Api::Job with the same args plus sequence_numbers' do
      expect(OpenStax::Biglearn::Api::Job).to(
        receive(:perform_later).with(job_args).and_call_original
      )

      job_with_sequence_number.perform(args)
    end

    it 'attempts to lock and work the newly created job inline' do
      delayed_job = Delayed::Job.new(handler: '')
      allow(Delayed::Job).to receive(:reserve_with_scope).and_return(delayed_job)
      expect(delayed_job).to receive(:invoke_job)

      job_with_sequence_number.perform(args)
    end
  end
end
