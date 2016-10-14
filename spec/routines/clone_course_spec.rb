require 'rails_helper'

RSpec.describe CloneCourse, type: :routine do

  let(:course) { FactoryGirl.create :entity_course }
  let(:user)   { FactoryGirl.create :user }

  it 'creates a copy of a course' do

    result = described_class.call(course: course, teacher_user: user)

    expect(result.errors).to be_empty

    course = result.outputs.course

    expect(course).to be_a Entity::Course
    expect(course.course_assistants.count).to eq 4
    expect(UserIsCourseTeacher[user: user, course: course]).to eq true

  end

end
