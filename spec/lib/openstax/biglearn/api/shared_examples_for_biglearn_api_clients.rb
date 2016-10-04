require 'rails_helper'

RSpec.shared_examples 'biglearn api clients' do
  let(:configuration) { OpenStax::Biglearn::Api.configuration }
  subject(:client)    { described_class.new(configuration) }

  dummy_ecosystem = OpenStruct.new tutor_uuid: SecureRandom.uuid
  dummy_book_container = OpenStruct.new tutor_uuid: SecureRandom.uuid
  dummy_course = OpenStruct.new uuid: SecureRandom.uuid
  dummy_period = OpenStruct.new uuid: SecureRandom.uuid
  dummy_task = OpenStruct.new uuid: SecureRandom.uuid
  dummy_student = OpenStruct.new uuid: SecureRandom.uuid
  dummy_exercise_ids = [SecureRandom.uuid, '4', "#{SecureRandom.uuid}@1", '4@2']
  max_exercises_to_return = 5
  preparation_uuid = SecureRandom.uuid

  context 'semi-deterministic requests' do
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
        [ :fetch_assignment_spes,
          [ { task: dummy_task, max_exercises_to_return: max_exercises_to_return } ],
          [ { assignment_uuid: dummy_task.uuid,
              exercise_uuids: [],
              assignment_status: :assignment_ready } ] ],
        [ :fetch_practice_worst_areas_pes,
          [ { student: dummy_student, max_exercises_to_return: max_exercises_to_return } ],
          [ { student_uuid: dummy_student.uuid,
              exercise_uuids: [],
              assignment_status: :assignment_ready } ] ]
    ].each do |method, requests, expected_responses|
      context "##{method}" do
        it 'returns the expected response for the given requests' do
          if requests.is_a?(Array)
            request_uuids = requests.map{ SecureRandom.uuid }
            requests = requests.each_with_index.map do |request, index|
              request.merge(request_uuid: request_uuids[index])
            end
            expected_responses = expected_responses.each_with_index
                                                   .map do |expected_response, index|
              expected_response.merge(request_uuid: request_uuids[index])
            end
          end

          expect([client.send(method, requests)].flatten).to(
            match_array([expected_responses].flatten)
          )
        end
      end
    end
  end

  context 'non-deterministic requests' do
    context '#fetch_assignment_pes' do
      xit 'returns PEs for the given tasks' do

      end
    end

    context '#fetch_assignment_spes' do
      xit 'returns SPEs for the given tasks' do

      end
    end

    context '#fetch_practice_worst_areas_pes' do
      xit 'returns PEs for the given student' do

      end
    end

    context '#fetch_student_clues' do
      xit 'returns student CLUes' do

      end
    end

    context '#fetch_teacher_clues' do
      xit 'returns period CLUes' do

      end
    end
  end
end
