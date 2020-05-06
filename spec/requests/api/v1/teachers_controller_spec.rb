require 'rails_helper'

RSpec.describe Api::V1::TeachersController, type: :request, api: true, version: :v1 do
  let(:application)        { FactoryBot.create :doorkeeper_application }

  let(:course)             { FactoryBot.create :course_profile_course }
  let(:period)             { FactoryBot.create :course_membership_period, course: course }

  let(:student_user)       { FactoryBot.create(:user_profile) }
  let(:student_role)       { AddUserAsPeriodStudent[user: student_user, period: period] }
  let!(:student)           { student_role.student }
  let(:student_token)      do
    FactoryBot.create :doorkeeper_access_token, application: application,
                                                resource_owner_id: student_user.id
  end

  let(:teacher_user)       { FactoryBot.create(:user_profile) }
  let!(:teacher)           { AddUserAsCourseTeacher[user: teacher_user, course: course].teacher }
  let!(:teacher_student_1) do
    CreateOrResetTeacherStudent[user: teacher_user, period: period].teacher_student
  end
  let!(:teacher_student_2) do
    CreateOrResetTeacherStudent[user: teacher_user, period: period].teacher_student
  end
  let(:teacher_token)      do
    FactoryBot.create :doorkeeper_access_token, application: application,
                                                resource_owner_id: teacher_user.id
  end

  context '#destroy' do
    before do
      expect(UserIsCourseTeacher[course: course, user: teacher_user]).to eq true
      expect(teacher.reload.deleted?).to eq false
      expect(teacher_student_1.reload.deleted?).to eq true
      expect(teacher_student_2.reload.deleted?).to eq false
    end

    context 'anonymous user' do
      it 'raises SecurityTransgression' do
        expect do
          api_delete api_teacher_url(teacher.id), nil
        end.to  raise_error(SecurityTransgression)
           .and not_change { UserIsCourseTeacher[course: course, user: teacher_user] }
           .and not_change { teacher.reload.deleted? }
           .and not_change { teacher_student_1.reload.deleted? }
           .and not_change { teacher_student_2.reload.deleted? }
      end
    end

    context 'user is a student' do
      it 'raises SecurityTransgression' do
        expect do
          api_delete api_teacher_url(teacher.id), student_token
        end.to  raise_error(SecurityTransgression)
           .and not_change { UserIsCourseTeacher[course: course, user: teacher_user] }
           .and not_change { teacher.reload.deleted? }
           .and not_change { teacher_student_1.reload.deleted? }
           .and not_change { teacher_student_2.reload.deleted? }
      end
    end

    context 'user is a teacher' do
      it 'removes the teacher and their teacher_students' do
        expect do
          api_delete api_teacher_url(teacher.id), teacher_token
        end.to  change     { UserIsCourseTeacher[course: course, user: teacher_user] }.to(false)
           .and change     { teacher.reload.deleted? }.to(true)
           .and not_change { teacher_student_1.reload.deleted? }
           .and change     { teacher_student_2.reload.deleted? }.to(true)
      end
    end
  end
end
