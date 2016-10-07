require 'rails_helper'

RSpec.describe Admin::CoursesDestroy, type: :handler do
  let!(:course) { FactoryGirl.create :entity_course }

  context 'destroyable course' do
    it 'deletes the course and the course profile' do
      courses_count = Entity::Course.count
      profiles_count = CourseProfile::Models::Profile.count

      result = described_class.call(params: {id: course.id})
      expect(result.errors).to be_empty
      expect(Entity::Course.count).to eq courses_count - 1
      expect(CourseProfile::Models::Profile.count).to eq profiles_count - 1
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
