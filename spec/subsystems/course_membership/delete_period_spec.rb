require 'rails_helper'

module CourseMembership
  RSpec.describe DeletePeriod do
    it 'deletes periods... pretty simple' do
      course = CreateCourse[name: 'Course time']
      period = CreatePeriod[course: course, name: '1st']

      described_class[period: period]

      expect(CourseMembership::Models::Period.all).to be_empty
    end
  end
end
