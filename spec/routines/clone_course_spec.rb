require 'rails_helper'

RSpec.describe CloneCourse, type: :routine do

  let(:course) { FactoryBot.create :course_profile_course }
  let(:user)   { FactoryBot.create :user }

  it 'creates a copy of a course' do

    result = described_class.call(
      course: course,
      teacher_user: user,
      copy_question_library: false,
      estimated_student_count: 100
    )

    expect(result.errors).to be_empty

    clone = result.outputs.course

    expect(clone).to be_a CourseProfile::Models::Course
    expect(clone.cloned_from).to eq course
    expect(clone.estimated_student_count).to eq 100
    expect(clone.course_assistants.count).to eq 4
    expect(UserIsCourseTeacher[user: user, course: clone]).to eq true

  end

  it "copies the course's question library if requested" do

    10.times{ FactoryBot.create :course_content_excluded_exercise, course: course }

    result = described_class.call(course: course, teacher_user: user, copy_question_library: true)

    expect(result.errors).to be_empty

    clone = result.outputs.course

    expect(clone).to be_a CourseProfile::Models::Course
    expect(clone.cloned_from).to eq course
    expect(clone.course_assistants.count).to eq 4
    expect(UserIsCourseTeacher[user: user, course: clone]).to eq true
    expect(clone.excluded_exercises.map(&:exercise_number)).to(
      match_array(course.excluded_exercises.map(&:exercise_number))
    )

  end

end
