require 'rails_helper'

RSpec.describe Api::V1::TeacherRepresenter, type: :representer do
  let(:user)    { FactoryBot.create(:user_profile) }
  let(:course)  { FactoryBot.create(:course_profile_course) }
  let(:teacher) { AddUserAsCourseTeacher.call(course: course, user: user).outputs.teacher }

  it 'represents a teacher' do
    representation = Api::V1::TeacherRepresenter.new(teacher.reload).as_json

    expect(representation).to eq(
      'id' => teacher.id.to_s,
      'course_id' => course.id.to_s,
      'role_id' => teacher.role.id.to_s,
      'research_identifier' => teacher.research_identifier,
      'first_name' => teacher.first_name,
      'last_name' => teacher.last_name,
      'profile_id' => teacher.role.profile.id.to_s,
      'name' => teacher.name,
      'is_active' => true,
      'joined_at' => DateTimeUtilities.to_api_s(teacher.created_at)
    )
  end
end
