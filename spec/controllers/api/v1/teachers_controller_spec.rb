require 'rails_helper'

describe Api::V1::TeachersController, type: :controller, api: true, version: :v1 do
  let(:application)       { FactoryGirl.create :doorkeeper_application }

  let(:course)            { Entity::Course.create }
  let(:period)            { CreatePeriod[course: course] }

  let(:student_user)      { FactoryGirl.create(:user) }
  let(:student_role)      { AddUserAsPeriodStudent[user: student_user, period: period] }
  let!(:student)          { student_role.student }
  let(:student_token)     { FactoryGirl.create :doorkeeper_access_token,
                                               application: application,
                                               resource_owner_id: student_user.id }

  let(:teacher_user)      { FactoryGirl.create(:user) }
  let(:teacher_role)      { AddUserAsCourseTeacher[user: teacher_user, course: course] }
  let!(:teacher)          { teacher_role.teacher }
  let(:teacher_token)     { FactoryGirl.create :doorkeeper_access_token,
                                               application: application,
                                               resource_owner_id: teacher_user.id }

  describe '#destroy' do
    context 'anonymous user' do
      it 'raises SecurityTransgression' do
        expect {
          api_delete :destroy, nil, parameters: { id: teacher.id }
        }.to raise_error(SecurityTransgression)
        expect(UserIsCourseTeacher[course: course, user: teacher_user]).to be true
      end
    end

    context 'user is a student' do
      it 'raises SecurityTransgression' do
        expect {
          api_delete :destroy, student_token, parameters: { id: teacher.id }
        }.to raise_error(SecurityTransgression)
        expect(UserIsCourseTeacher[course: course, user: teacher_user]).to be true
      end
    end

    context 'user is a teacher' do
      it 'removes the teacher' do
        api_delete :destroy, teacher_token, parameters: { id: teacher.id }
        expect(UserIsCourseTeacher[course: course, user: teacher_user]).to be false
      end
    end
  end
end
