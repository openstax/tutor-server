require 'rails_helper'

RSpec.shared_examples 'biglearn api clients' do
  let(:dummy_ecosystem)         { OpenStruct.new tutor_uuid: SecureRandom.uuid }
  let(:dummy_book_container)    { OpenStruct.new tutor_uuid: SecureRandom.uuid }
  let(:dummy_course)            { OpenStruct.new uuid: SecureRandom.uuid }
  let(:dummy_period)            { OpenStruct.new uuid: SecureRandom.uuid }
  let(:dummy_task)              { OpenStruct.new uuid: SecureRandom.uuid }
  let(:dummy_student)           { OpenStruct.new uuid: SecureRandom.uuid }
  let(:dummy_exercise_ids)      { [SecureRandom.uuid, '4', "#{SecureRandom.uuid}@1", '4@2'] }
  let(:max_exercises_to_return) { 5 }
end
