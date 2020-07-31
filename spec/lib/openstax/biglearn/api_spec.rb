require 'rails_helper'
require 'database_cleaner'

RSpec.describe OpenStax::Biglearn::Api, type: :external do
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
      @ecosystem_1 = reading_task_plan.ecosystem
      @ecosystem_2 = FactoryBot.create :content_ecosystem
      @page = @ecosystem_1.pages.first
      @exercises = @page.exercises
      @course = reading_task_plan.course
      @course.update_attribute :is_preview, true
      @reading_task = reading_task_plan.tasks.first
      @tasked_exercise = @reading_task.tasked_exercises.first
      @student = @reading_task.taskings.first.role.student
      @period = @student.period
      FactoryBot.create :course_content_excluded_exercise, course: @course
    end

    after(:all) { DatabaseCleaner.clean }

    before do
      @course.reload
      @ecosystem_1.reload

      allow(described_class).to receive(:use_fake_client) { |&block| block.call }
      expect(described_class).not_to receive(:use_real_client)
    end

    let(:max_num_exercises) { 5 }

    context 'with default perform_later' do
      [
        [
          :create_ecosystem,
          -> { { ecosystem: @ecosystem_1.tap { |eco| eco.update_attribute :sequence_number, 0 } } },
          nil,
          described_class::JobWithSequenceNumber,
          -> { @ecosystem_1 },
          1
        ],
        [
          :create_course,
          -> { { course: @course.tap { |course| course.update_attribute :sequence_number, 0 },
                 ecosystem: @ecosystem_1 } },
          nil,
          described_class::JobWithSequenceNumber,
          -> { @course },
          1
        ],
        [
          :prepare_course_ecosystem,
          -> { { course: @course, from_ecosystem: @ecosystem_1, to_ecosystem: @ecosystem_2 } },
          nil,
          Hash,
          -> { @course },
          1
        ],
        [
          :update_course_ecosystems,
          -> { [ { course: @course, preparation_uuid: SecureRandom.uuid } ] },
          nil,
          described_class::JobWithSequenceNumber,
          -> { @course },
          1
        ],
        [
          :sequentially_prepare_and_update_course_ecosystem,
          -> { { course: @course, from_ecosystem: @ecosystem_1, to_ecosystem: @ecosystem_2 } },
          nil,
          Hash,
          -> { @course },
          2
        ],
        [
          :update_rosters,
          -> { [ { course: @course }, { enable_warnings: false } ] },
          nil,
          described_class::JobWithSequenceNumber,
          -> { @course },
          1
        ],
        [
          :update_globally_excluded_exercises,
          -> { { course: @course, enable_warnings: false } },
          nil,
          described_class::JobWithSequenceNumber,
          -> { @course },
          1
        ],
        [
          :update_course_excluded_exercises,
          -> { { course: @course } },
          -> { { enable_warnings: false } },
          described_class::JobWithSequenceNumber,
          -> { @course },
          1
        ],
        [
          :update_course_active_dates,
          -> { { course: @course } },
          nil,
          described_class::JobWithSequenceNumber,
          -> { @course },
          1
        ],
        [
          :create_update_assignments,
          -> { [ { course: @course, task: @reading_task } ] },
          nil,
          described_class::JobWithSequenceNumber,
          -> { @course },
          1
        ],
        [
          :record_responses,
          -> { [ { course: @course, tasked_exercise: @tasked_exercise } ] },
          nil,
          described_class::JobWithSequenceNumber,
          -> { @course },
          1
        ],
        [
          :fetch_assignment_pes,
          -> { [ { task: @reading_task, max_num_exercises: max_num_exercises } ] },
          nil,
          Hash,
          -> { @course },
          0
        ],
        [
          :fetch_assignment_spes,
          -> { [ { task: @reading_task, max_num_exercises: max_num_exercises } ] },
          nil,
          Hash,
          -> { @course },
          0
        ],
        [
          :fetch_practice_worst_areas_exercises,
          -> { [ { student: @student, max_num_exercises: max_num_exercises } ] },
          nil,
          Hash,
          -> { @course },
          0
        ],
        [
          :fetch_student_clues,
          -> { [ { book_container_uuid: @page.tutor_uuid, student: @student } ] },
          nil,
          Hash,
          -> { @course },
          0
        ],
        [
          :fetch_teacher_clues,
          -> { [ { book_container_uuid: @page.tutor_uuid, course_container: @period } ] },
          nil,
          Hash,
          -> { @course },
          0
        ]
      ].each do |method, requests_proc, options_proc, result_class,
                 sequence_number_record_proc, increment|
        it "delegates #{method} to the client implementation and returns a job or response" do
          requests = instance_exec &requests_proc
          options = instance_exec(&options_proc) unless options_proc.nil?
          sequence_number_record = instance_exec &sequence_number_record_proc

          sequence_number = sequence_number_record.sequence_number \
            if sequence_number_record.present?

          if method != :create_ecosystem && @course.is_preview
            expect(described_class).to receive(:use_fake_client).at_least(:once) do |&block|
              block.call
            end
          else
            expect(described_class).not_to receive(:use_fake_client)
          end
          expect(described_class.client).to receive(method).and_call_original

          results = options.nil? ? described_class.send(method, requests) :
                                   described_class.send(method, requests, options)

          results = results.values if requests.is_a?(Array) && results.is_a?(Hash)

          [results].flatten.each { |result| expect(result).to be_a result_class }

          expect(sequence_number_record.reload.sequence_number).to(
            eq(sequence_number + increment)
          ) if sequence_number_record.present?
        end
      end
    end

    context '#prepare_and_update_course_ecosystem' do
      context 'new course' do
        before { @course.update_attribute :sequence_number, 0 }

        it 'makes the expected method calls' do
          expect(described_class.client).to receive(:create_course).and_call_original

          expect(described_class.client).to receive(:update_globally_excluded_exercises)
          expect(described_class.client).to receive(:update_course_excluded_exercises)
          expect(described_class.client).to receive(:update_rosters)
          expect(described_class.client).to receive(:update_course_active_dates)

          described_class.prepare_and_update_course_ecosystem course: @course
        end
      end

      context 'existing course' do
        it 'makes the expected method call' do
          expect(described_class.client).to(
            receive(:sequentially_prepare_and_update_course_ecosystem)
          )

          described_class.prepare_and_update_course_ecosystem course: @course
        end
      end
    end

    it 'errors when given too many arguments' do
      expect do
        described_class.update_course_ecosystems([], { what: true }, { enable_warnings: false })
      end.to raise_error(ArgumentError)
    end

    it 'converts returned exercise uuids to exercise objects, preserving their order' do
      expect(@exercises).not_to be_empty
      exercises = @exercises.first(max_num_exercises)
      expect(Rails.logger).not_to receive(:warn)

      [ :fetch_assignment_pes, :fetch_assignment_spes ].each do |api_method|
        expect(described_class.client).to receive(api_method) do |requests|
          requests.map do |request|
            {
              request_uuid: request[:request_uuid],
              exercise_uuids: exercises.map(&:uuid),
              assignment_status: 'assignment_ready'
            }
          end
        end.once

        result = nil
        expect do
          result = described_class.public_send(
            api_method, task: @reading_task, max_num_exercises: max_num_exercises
          )
        end.not_to raise_error
        expect(result.fetch(:accepted)).to eq true
        expect(result.fetch(:exercises)).to eq exercises
      end
    end

    it 'returns accepted: false and falls back to random personalized exercises' +
       ' if no valid Biglearn response' do
      homework_task = FactoryBot.create :tasks_task, task_type: :homework, tasked_to: @student.role
      practice_task = FactoryBot.create :tasks_task, task_type: :page_practice,
                                                     tasked_to: @student.role

      [ :fetch_assignment_pes, :fetch_assignment_spes ].each do |api_method|
        [ @reading_task, homework_task, practice_task ].each do |task|
          expect(described_class.client).to receive(api_method) do |requests|
            requests.map do |request|
              {
                request_uuid: request[:request_uuid],
                exercise_uuids: [],
                assignment_status: 'assignment_unready'
              }
            end
          end.exactly(3).times
          if task == @reading_task
            expect(Rails.logger).to receive(:warn).twice.and_call_original
          else
            expect(Rails.logger).to receive(:warn).once.and_call_original
          end

          core_page_ids = GetTaskCorePageIds[tasks: task][task.id]

          result = nil
          expect do
            result = described_class.public_send(
              api_method,
              task: task,
              max_num_exercises: max_num_exercises,
              inline_sleep_interval: 0.01.second,
              inline_max_attempts: 3
            )
          end.not_to raise_error
          expect(result.fetch(:accepted)).to eq false
          exercises = result.fetch(:exercises)
          expect(exercises.size).to eq task == @reading_task ? max_num_exercises : 0
          exercises.each do |exercise|
            expect(core_page_ids).to include(exercise.content_page_id)
          end
        end
      end
    end

    it 'errors when client returns more exercises than expected' do
      [ :fetch_assignment_pes, :fetch_assignment_spes ].each do |api_method|
        expect(described_class.client).to receive(api_method) do |requests|
          requests.map do |request|
            {
              request_uuid: request[:request_uuid],
              exercise_uuids: (max_num_exercises + 1).times.map { SecureRandom.uuid },
              assignment_status: 'assignment_ready'
            }
          end
        end
        expect(Rails.logger).not_to receive(:warn)

        expect do
          described_class.public_send(
            api_method, task: @reading_task, max_num_exercises: max_num_exercises
          )
        end.to raise_error { OpenStax::Biglearn::ExercisesError }
      end
    end

    it 'logs a warning when client returns less exercises than expected' do
      exercises = @exercises.first(max_num_exercises - 1)

      [ :fetch_assignment_pes, :fetch_assignment_spes ].each do |api_method|
        expect(described_class.client).to receive(api_method) do |requests|
          requests.map do |request|
            {
              request_uuid: request[:request_uuid],
              exercise_uuids: exercises.map(&:uuid),
              assignment_status: 'assignment_ready'
            }
          end
        end
        expect(Rails.logger).to receive(:warn)

        result = nil
        expect do
          result = described_class.public_send(
            api_method, task: @reading_task, max_num_exercises: max_num_exercises
          )
        end.not_to raise_error
        expect(result.fetch(:exercises)).to match_array(exercises)
      end
    end

    it 'errors when client returns exercises not present locally' do
      [ :fetch_assignment_pes, :fetch_assignment_spes ].each do |api_method|
        expect(described_class.client).to receive(api_method) do |requests|
          requests.map do |request|
            {
              request_uuid: request[:request_uuid],
              exercise_uuids: max_num_exercises.times.map { SecureRandom.uuid },
              assignment_status: 'assignment_ready'
            }
          end
        end
        expect(Rails.logger).not_to receive(:warn)

        expect do
          described_class.public_send(
            api_method, task: @reading_task, max_num_exercises: max_num_exercises
          )
        end.to raise_error { OpenStax::Biglearn::ExercisesError }
      end
    end
  end
end
