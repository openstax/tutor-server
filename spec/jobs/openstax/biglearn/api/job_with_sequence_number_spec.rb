require 'rails_helper'

RSpec.describe OpenStax::Biglearn::Api::JobWithSequenceNumber, type: :job do
  subject(:job_with_sequence_number)  { described_class.new }

  let(:course)                        { FactoryBot.create :course_profile_course }

  let(:sequence_number_model_key)     { :course }
  let(:sequence_number_model_class)   { CourseProfile::Models::Course }

  let(:perform_later_args)             do
    {
      method: method.to_s,
      requests: requests,
      create: create,
      sequence_number_model_key: sequence_number_model_key.to_s,
      sequence_number_model_class: sequence_number_model_class.to_s,
      queue: 'low_priority'
    }
  end
  let(:perform_args)                   do
    {
      method: method,
      requests: requests,
      create: create,
      sequence_number_model_key: sequence_number_model_key,
      sequence_number_model_class: sequence_number_model_class,
      queue: 'high_priority'
    }
  end
  let(:job_args)                      do
    {
      method: method.to_s,
      requests: requests_with_sequence_numbers,
      response_status_key: nil,
      accepted_response_status: []
    }
  end

  context 'create' do
    let(:method)                         { :create_course }
    let(:requests)                       { { course: course } }
    let(:requests_with_sequence_numbers) { requests.merge sequence_number: course.sequence_number }
    let(:create)                         { true }

    context 'when the course\'s sequence_number is 0' do
      before { course.update_attribute :sequence_number, 0 }

      it 'delegates #perform to a new instance of itself' do
        allow(described_class).to receive(:new).and_return(job_with_sequence_number)
        expect(job_with_sequence_number).to receive(:perform).with(perform_args)

        described_class.perform(perform_args)
      end

      it 'increments the course\'s sequence_number' do
        expect do
          job_with_sequence_number.perform(perform_args)
        end.to change { course.sequence_number }.by(1)
      end

      context 'when delay_jobs is true' do
        before { allow(Delayed::Worker).to receive(:delay_jobs).and_return(true) }

        context '#perform_later' do
          it 'uses ActiveJob::AfterCommitRunner to lock and work its own job inline' do
            runner = ActiveJob::AfterCommitRunner.new(job_with_sequence_number)

            expect(ActiveJob::AfterCommitRunner).to receive(:new) do |job|
              expect(job).to be_a described_class
            end.and_return(runner)
            expect(runner).to receive(:run_after_commit)

            described_class.perform_later(perform_later_args)
          end
        end

        context '#perform' do
          it 'creates a new OpenStax::Biglearn::Api::Job with same args plus sequence_numbers' do
            expect(OpenStax::Biglearn::Api::Job).to(
              receive(:set).with(queue: 'high_priority').and_return(OpenStax::Biglearn::Api::Job)
            )
            expect(OpenStax::Biglearn::Api::Job).to(
              receive(:perform_later).with(job_args).and_call_original
            )

            job_with_sequence_number.perform(perform_args)
          end
        end
      end
    end

    context 'when the course\'s sequence_number is not 0' do
      it 'fails with an ArgumentError so the job does not retry' do
        expect{ job_with_sequence_number.perform(perform_args) }.to raise_error(ArgumentError)
      end
    end
  end

  context 'update_rosters' do
    let(:method)                         { :update_rosters }
    let(:requests)                       { [ { request_uuid: SecureRandom.uuid, course: course } ] }
    let(:requests_with_sequence_numbers) do
      requests.map do |request|
        request.merge sequence_number: course.sequence_number
      end
    end
    let(:create)                         { false }

    context 'when the course\'s sequence_number is 0' do
      before { course.update_attribute :sequence_number, 0 }

      it 'fails with an OpenStax::Biglearn::Api::JobFailed so the job can retry later' do
        expect{ job_with_sequence_number.perform(perform_args) }.to(
          raise_error(OpenStax::Biglearn::Api::JobFailed)
        )
      end
    end

    context 'when the course\'s sequence_number is not 0' do
      it 'delegates #perform to a new instance of itself' do
        allow(described_class).to receive(:new).and_return(job_with_sequence_number)
        expect(job_with_sequence_number).to receive(:perform).with(perform_args)

        described_class.perform(perform_args)
      end

      it 'increments the course\'s sequence_number' do
        expect do
          job_with_sequence_number.perform(perform_args)
        end.to change { course.sequence_number }.by(1)
      end

      context 'when delay_jobs is true' do
        before { allow(Delayed::Worker).to receive(:delay_jobs).and_return(true) }

        context '#perform_later' do
          it 'uses ActiveJob::AfterCommitRunner to lock and work its own job inline' do
            runner = ActiveJob::AfterCommitRunner.new(job_with_sequence_number)

            expect(ActiveJob::AfterCommitRunner).to receive(:new) do |job|
              expect(job).to be_a described_class
            end.and_return(runner)
            expect(runner).to receive(:run_after_commit)

            described_class.perform_later(perform_later_args)
          end
        end

        context '#perform' do
          it 'creates a new OpenStax::Biglearn::Api::Job with same args plus sequence_numbers' do
            expect(OpenStax::Biglearn::Api::Job).to(
              receive(:set).with(queue: 'high_priority').and_return(OpenStax::Biglearn::Api::Job)
            )
            expect(OpenStax::Biglearn::Api::Job).to(
              receive(:perform_later).with(job_args).and_call_original
            )

            job_with_sequence_number.perform(perform_args)
          end
        end
      end
    end
  end
end
