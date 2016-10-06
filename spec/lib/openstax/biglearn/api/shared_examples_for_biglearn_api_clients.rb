require 'rails_helper'

RSpec.shared_examples 'a biglearn api client' do
  let(:configuration) { OpenStax::Biglearn::Api.configuration }
  subject(:client)    { described_class.new(configuration) }

  let(:clue_matcher) do
    {
      value: kind_of(Float),
      value_interpretation: kind_of(Symbol),
      confidence_interval: [kind_of(Float), kind_of(Float)],
      confidence_interval_interpretation: kind_of(Symbol),
      sample_size: kind_of(Integer),
      sample_size_interpretation: kind_of(Symbol),
      unique_learner_count: kind_of(Integer)
    }
  end

  dummy_ecosystem = OpenStruct.new tutor_uuid: SecureRandom.uuid
  dummy_book_container = OpenStruct.new tutor_uuid: SecureRandom.uuid
  dummy_course = OpenStruct.new uuid: SecureRandom.uuid
  dummy_course_container = OpenStruct.new uuid: SecureRandom.uuid
  dummy_task = OpenStruct.new uuid: SecureRandom.uuid, task_type: 'practice'
  dummy_student = OpenStruct.new uuid: SecureRandom.uuid
  dummy_exercise_ids = [SecureRandom.uuid, '4', "#{SecureRandom.uuid}@1", '4@2']
  max_exercises_to_return = 5
  preparation_uuid = SecureRandom.uuid

  task_with_pes = FactoryGirl.create(:tasked_task_plan).tasks.first

  [
    [ :create_ecosystem, { ecosystem: dummy_ecosystem },
                         { created_ecosystem_uuid: dummy_ecosystem.tutor_uuid } ],
    [ :create_course, { course: dummy_course, ecosystem: dummy_ecosystem },
                      { created_course_uuid: dummy_course.uuid } ],
    [ :prepare_course_ecosystem, { preparation_uuid: preparation_uuid,
                                   course: dummy_course, ecosystem: dummy_ecosystem },
                                 { prepare_status: :accepted } ],
    [ :update_course_ecosystems, [ { preparation_uuid: preparation_uuid } ],
                                 [ { update_status: :updated_and_ready } ] ],
    [ :update_rosters, [ { course: dummy_course } ],
                       [ { updated_course_uuid: dummy_course.uuid } ] ],
    [ :update_global_exercise_exclusions, { exercise_ids: dummy_exercise_ids },
                                          { updated_exercise_ids: dummy_exercise_ids } ],
    [ :update_course_exercise_exclusions, { course: dummy_course },
                                          { updated_course_uuid: dummy_course.uuid } ],
    [ :create_update_assignments, [ { task: dummy_task } ],
                                  [ { assignment_uuid: dummy_task.uuid,
                                      sequence_number: dummy_task.sequence_number } ] ],
    [ :fetch_assignment_pes,
      [ { task: dummy_task, max_exercises_to_return: max_exercises_to_return } ],
      [ { assignment_uuid: dummy_task.uuid,
          exercise_uuids: [],
          assignment_status: :assignment_ready } ] ],
    [ :fetch_assignment_pes,
      [ { task: task_with_pes, max_exercises_to_return: max_exercises_to_return } ],
      [ ->{ { assignment_uuid: task_with_pes.uuid,
              exercise_uuids: [kind_of(String)]*max_exercises_to_return,
              assignment_status: :assignment_ready } } ] ],
    [ :fetch_assignment_spes,
      [ { task: dummy_task, max_exercises_to_return: max_exercises_to_return } ],
      [ { assignment_uuid: dummy_task.uuid,
          exercise_uuids: [],
          assignment_status: :assignment_ready } ] ],
    [ :fetch_practice_worst_areas_pes,
      [ { student: dummy_student, max_exercises_to_return: max_exercises_to_return } ],
      [ { student_uuid: dummy_student.uuid,
          exercise_uuids: [],
          assignment_status: :assignment_ready } ] ],
    [ :fetch_student_clues,
      [ { book_container: dummy_book_container, student: dummy_student } ],
      [ ->{ { clue_data: clue_matcher, clue_status: :clue_ready } } ] ],
    [ :fetch_teacher_clues,
      [ { book_container: dummy_book_container, course_container: dummy_course_container } ],
      [ ->{ { clue_data: clue_matcher, clue_status: :clue_ready } } ] ]
  ].group_by(&:first).each do |method, examples|
    context "##{method}" do
      examples.each_with_index do |(method, requests, expected_responses), index|
        it "returns the expected response for the #{(index + 1).ordinalize} set of requests" do
          expected_responses = instance_exec(&expected_responses) if expected_responses.is_a?(Proc)

          if requests.is_a?(Array)
            request_uuids = requests.map{ SecureRandom.uuid }
            requests = requests.each_with_index.map do |request, index|
              request.merge(request_uuid: request_uuids[index])
            end
            expected_responses = expected_responses.each_with_index
                                                   .map do |expected_response, index|
              expected_response = instance_exec(&expected_response) if expected_response.is_a?(Proc)
              expected_response.merge(request_uuid: request_uuids[index])
            end
          end

          actual_responses = client.send(method, requests)

          expect([actual_responses].flatten).to match_array([expected_responses].flatten)
        end
      end
    end
  end
end
