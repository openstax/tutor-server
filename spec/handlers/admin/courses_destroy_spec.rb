require 'rails_helper'

RSpec.describe Admin::CoursesDestroy, type: :handler do
  let!(:course) { FactoryGirl.create :course_profile_course }

  context 'destroyable course' do
    it 'deletes the course' do
      result = nil
      expect do
        result = described_class.call(params: {id: course.id})
      end.to change{ course.reload.deleted? }.from(false).to(true)
      expect(result.errors).to be_empty
    end
  end

  context 'non-destroyable course' do
    before{ FactoryGirl.create :course_membership_period, course: course }

    it 'returns an error' do
      result = described_class.call(params: {id: course.id})
      expect(result.errors.first.code).to eq :course_not_empty
    end
  end
end
