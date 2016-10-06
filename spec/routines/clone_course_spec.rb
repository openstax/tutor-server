require 'rails_helper'

describe CloneCourse, type: :routine do

  let(:source)  { CreateCourse[name: 'source'] }
  let(:user)    { FactoryGirl.create(:user) }

  it "creates a copy of a course" do

    result = CloneCourse.call(course: source, teacher: user)

    expect(result.errors).to be_empty

    course = result.outputs.course

    expect(course).to be_a Entity::Course
    expect(course.course_assistants.count).to eq 4
    expect(UserIsCourseTeacher[user: user, course: course]).to be_truthy

  end


end
