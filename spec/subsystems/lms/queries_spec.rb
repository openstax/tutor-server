require 'rails_helper'

RSpec.describe Lms::Queries do

  let(:course) { FactoryBot.create :course_profile_course }
  let(:context) { FactoryBot.create :lms_context, course: course }

  context '#app_for_course' do
    it 'returns the app when course-owned' do
      expected_app = FactoryBot.create(:lms_app, owner: course)
      course.lms_context = context
      expect(described_class.app_for_course(course)).to eq expected_app
    end

    it 'freaks out if no connected app' do
      expect{described_class.app_for_course(course)}.to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'finds willo labs when its configured' do
      FactoryBot.create(:lms_app, owner: course)
      course.lms_context = context
      course.lms_context.update_attributes app_type: 'Lms::WilloLabs'
      expect(described_class.app_for_course(course)).to be_a(Lms::WilloLabs)
    end

  end

end
