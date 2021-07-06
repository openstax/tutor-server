require 'rails_helper'

RSpec.describe AddUserAsCourseTeacher, type: :routine do
  context 'when the user is not a teacher in the course' do
    it "returns the user's new teacher role" do
      user = FactoryBot.create :user_profile
      course = FactoryBot.create :course_profile_course

      result = AddUserAsCourseTeacher.call(user: user, course: course)
      expect(result.errors).to be_empty
      expect(result.outputs.role).to_not be_nil
    end
  end

  context 'when the user is already a teacher in the course' do
    context 'when the teacher is not deleted' do
      it 'errors' do
        user = FactoryBot.create :user_profile
        course = FactoryBot.create :course_profile_course

        result = AddUserAsCourseTeacher.call(user: user, course: course)
        expect(result.errors).to be_empty
        expect(result.outputs.role).to_not be_nil

        result = AddUserAsCourseTeacher.call(user: user, course: course)
        expect(result.errors).to_not be_empty
      end
    end

    context 'when the teacher is deleted' do
      it 'restores the teacher' do
        user = FactoryBot.create :user_profile
        course = FactoryBot.create :course_profile_course

        result = AddUserAsCourseTeacher.call(user: user, course: course)
        expect(result.errors).to be_empty

        teacher = result.outputs.teacher
        teacher.destroy!

        result = AddUserAsCourseTeacher.call(user: user, course: course)
        expect(result.errors).to be_empty
        expect(result.outputs.teacher).to eq teacher
        expect(teacher.reload).not_to be_deleted
      end
    end
  end
end
