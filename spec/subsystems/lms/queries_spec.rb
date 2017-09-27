require 'rails_helper'

RSpec.describe Lms::Queries do

  let(:course) { FactoryGirl.create :course_profile_course }

  context '#app_for_course' do
    it 'returns the app when course-owned' do
      expected_app = FactoryGirl.create(:lms_app, owner: course)
      expect(described_class.app_for_course(course)).to eq expected_app
    end

    it 'freaks out if no connected app' do
      expect{described_class.app_for_course(course)}.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

end
