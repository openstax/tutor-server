require 'rails_helper'

RSpec.shared_examples 'a biglearn api client' do
  let(:configuration) { OpenStax::Biglearn::Api.configuration }
  subject(:client)    { described_class.new(configuration) }

  let(:clue_matcher) do
    a_hash_including(
      minimum: kind_of(Numeric),
      most_likely: kind_of(Numeric),
      maximum: kind_of(Numeric),
      is_real: be_in([true, false])
    )
  end

  before(:all) do
    task_plan_1 = FactoryGirl.create(:tasked_task_plan)
    @ecosystem_1 = task_plan_1.ecosystem
    @book_1 = @ecosystem_1.books.first
    @chapter_1 = @book_1.chapters.first
    @page_1 = @chapter_1.pages.first
    @exercise_1 = @page_1.exercises.first

    task_plan_2 = FactoryGirl.create(:tasked_task_plan)
    @ecosystem_2 = task_plan_2.ecosystem
    @book_2 = @ecosystem_2.books.first
    @chapter_2 = @book_2.chapters.first
    @page_2 = @chapter_2.pages.first
    @exercise_2 = @page_2.exercises.first

    @task = task_plan_1.tasks.first
    @tasked_exercise = @task.tasked_exercises.first

    @student = @task.taskings.first.role.student
    @period = @student.latest_enrollment.period
    @course = @period.course

    @preparation_uuid = SecureRandom.uuid

    @max_num_exercises = 5
  end

  when_tagged_with_vcr = { vcr: ->(v) { !!v } }

  before(:all, when_tagged_with_vcr) do
    VCR.configure do |config|
      config.ignore_localhost = false
      config.define_cassette_placeholder('<ECOSYSTEM 1 UUID>') { @ecosystem_1.tutor_uuid }
      config.define_cassette_placeholder('<COURSE UUID>'     ) { @course.uuid            }
      config.define_cassette_placeholder('<TASK UUID>'       ) { @task.uuid              }
      config.define_cassette_placeholder('<STUDENT UUID>'    ) { @student.uuid           }
    end
  end

  after(:all, when_tagged_with_vcr) { VCR.configuration.ignore_localhost = true }

  [
    [ :create_ecosystem,
      -> { { ecosystem: @ecosystem_1 } },
      -> { { created_ecosystem_uuid: @ecosystem_1.tutor_uuid } } ],
    [ :create_course,
      -> { { course: @course, ecosystem: @ecosystem_1 } },
      -> { { created_course_uuid: @course.uuid } } ],
    [ :prepare_course_ecosystem,
      -> { { course: @course,
             sequence_number: @course.sequence_number,
             preparation_uuid: @preparation_uuid,
             ecosystem: @ecosystem_2 } },
      -> { { status: 'accepted' } } ],
    [ :update_course_ecosystems,
      [ -> { { course: @course,
               sequence_number: @course.sequence_number,
               preparation_uuid: @preparation_uuid } } ],
      [ -> { { update_status: a_kind_of(String) } } ] ],
    [ :update_rosters,
      [ -> { { course: @course, sequence_number: @course.sequence_number } } ],
      [ -> { { updated_course_uuid: @course.uuid } } ] ],
    [ :update_globally_excluded_exercises,
      -> { { course: @course, sequence_number: @course.sequence_number } },
      -> { { status: 'success' } } ],
    [ :update_course_excluded_exercises,
      -> { { course: @course, sequence_number: @course.sequence_number } },
      -> { { status: 'success' } } ],
    [ :update_course_active_dates,
      -> { { course: @course, sequence_number: @course.sequence_number } },
      -> { { updated_course_uuid: @course.uuid } } ],
    [ :create_update_assignments,
      [ -> { { course: @course, sequence_number: @course.sequence_number, task: @task } } ],
      [ -> { { updated_assignment_uuid: @task.uuid } } ] ],
    [ :record_responses,
      [ -> { { course: @course,
               sequence_number: @course.sequence_number,
               tasked_exercise: @tasked_exercise } } ],
      [ {} ],
      :response_uuid ],
    [ :fetch_assignment_pes,
      [ -> { { task: @task, max_num_exercises: @max_num_exercises } } ],
      [ -> { { assignment_uuid: @task.uuid,
               exercise_uuids: kind_of(Array),
               assignment_status: kind_of(String) } } ] ],
    [ :fetch_assignment_spes,
      [ -> { { task: @task, max_num_exercises: @max_num_exercises } } ],
      [ -> { { assignment_uuid: @task.uuid,
               exercise_uuids: [],
               assignment_status: kind_of(String) } } ] ],
    [ :fetch_practice_worst_areas_pes,
      [ -> { { student: @student, max_num_exercises: @max_num_exercises } } ],
      [ -> { { student_uuid: @student.uuid,
               exercise_uuids: [],
               student_status: kind_of(String) } } ] ],
    [ :fetch_student_clues,
      [ -> { { book_container: @page_1, student: @student } } ],
      [ -> { { clue_data: clue_matcher, clue_status: kind_of(String) } } ] ],
    [ :fetch_teacher_clues,
      [ -> { { book_container: @chapter_1, course_container: @period } } ],
      [ -> { { clue_data: clue_matcher, clue_status: kind_of(String) } } ] ]
  ].group_by(&:first).each do |method, examples|
    context "##{method}" do
      examples.each_with_index do |(method, requests, expected_responses, uuid_key), index|
        uuid_key ||= :request_uuid

        if requests.is_a?(Array)
          request_uuids = requests.map{ SecureRandom.uuid }

          before(:all, when_tagged_with_vcr) do
            VCR.configure do |config|
              requests.each_with_index do |request, request_index|
                config.define_cassette_placeholder(
                  "<#{method.to_s.upcase} EXAMPLE #{index + 1} REQUEST #{request_index + 1} UUID>"
                ) { request_uuids[index] }
              end
            end
          end
        end

        it "returns the expected response for the #{(index + 1).ordinalize} request" do
          # Ensure no sequence_number collisions with other specs during testing
          @course.uuid = SecureRandom.uuid

          requests = instance_exec(&requests) if requests.is_a?(Proc)
          expected_responses = instance_exec(&expected_responses) if expected_responses.is_a?(Proc)

          if requests.is_a?(Array)
            requests = requests.each_with_index.map do |request, index|
              request = instance_exec(&request) if request.is_a?(Proc)
              request.merge(uuid_key => request_uuids[index])
            end

            expected_responses = expected_responses.each_with_index.map do |response, index|
              response = instance_exec(&response) if response.is_a?(Proc)
              response.merge(uuid_key => request_uuids[index])
            end
          end

          actual_responses = client.send(method, requests)

          expect([actual_responses].flatten).to match_array([expected_responses].flatten)
        end
      end
    end
  end
end
