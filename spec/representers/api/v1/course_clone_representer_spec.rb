require 'rails_helper'
require_relative 'course_representer_shared_examples'

RSpec.describe Api::V1::CourseCloneRepresenter, type: :representer do
  include_examples 'api_v1_course_representer'

  context 'offering_id' do
    it 'cannot be written (attempts are silently ignored)' do
      course_params = OpenStruct.new
      described_class.new(course_params).from_hash('offering_id' => '42')
      expect(course_params.offering_id).to be_nil
      expect(course_params.catalog_offering_id).to be_nil
    end
  end

  context 'copy_question_library' do
    it 'cannot be read' do
      expect(represented['copy_question_library']).to be_nil
    end

    it 'can be written' do
      course_params = OpenStruct.new
      described_class.new(course_params).from_hash('copy_question_library' => true)
      expect(course_params.copy_question_library).to eq true
    end
  end
end
