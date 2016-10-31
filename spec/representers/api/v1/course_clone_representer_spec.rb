require 'rails_helper'
require_relative 'course_representer_shared_examples'

RSpec.describe Api::V1::CourseCloneRepresenter, type: :representer do
  include_examples 'api_v1_course_representer'

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
