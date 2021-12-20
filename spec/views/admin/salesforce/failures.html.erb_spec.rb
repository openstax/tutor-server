require 'rails_helper'

RSpec.describe 'admin/salesforce/failures', type: :view do
  let(:courses) do
    [
      FactoryBot.create(:course_profile_course),
      FactoryBot.create(:course_membership_teacher).course,
      FactoryBot.create(:course_membership_student).course
    ]
  end

  before(:each) { assign :courses, courses }

  it 'renders the given courses' do
    expect { render }.not_to raise_error

    expect(rendered).to include('Salesforce Update Failures')

    expect(rendered).to include('The following courses')
    expect(rendered).to include('have no teachers with a valid Salesforce Contact:')

    expect(rendered).to include('Course')
    expect(rendered).to include('Instructors')
    expect(rendered).to include('Enrolled Students')
    expect(rendered).to include('Dropped Students')
    expect(rendered).to include('Total Students')

    courses.each do |course|
      expect(rendered).to include(course.id.to_s)

      teachers = course.teachers.to_a
      expect(rendered).to include(teachers.empty? ? '---' : teachers.map(&:name).join('; '))

      students = course.students.to_a
      expect(rendered).to include(students.reject(&:dropped?).size.to_s)
      expect(rendered).to include(students.count(&:dropped?).to_s)
      expect(rendered).to include(students.size.to_s)
    end
  end
end
