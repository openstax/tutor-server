require 'rails_helper'

module CourseMembership
  RSpec.describe DeletePeriod do
    it 'deletes periods... pretty simple' do
      course = CreateCourse.call(name: 'Course time')
      period = CreatePeriod.call(course: course, name: '1st')

      described_class.call(period: period)

      expect(CourseMembership::Models::Period.all).to be_empty
    end
  end
end
