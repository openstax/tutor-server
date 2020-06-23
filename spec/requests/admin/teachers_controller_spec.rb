require 'rails_helper'

RSpec.describe Admin::TeachersController, type: :request do
  let(:admin)  { FactoryBot.create :user_profile, :administrator }

  let(:user_1) { FactoryBot.create :user_profile }
  let(:user_2) { FactoryBot.create :user_profile }

  let(:period) { FactoryBot.create :course_membership_period }
  let(:course) { period.course }

  before       { sign_in! admin }

  context 'POST #teachers' do
    before do
      expect(UserIsCourseTeacher[course: course, user: user_1]).to eq false
      expect(UserIsCourseTeacher[course: course, user: user_2]).to eq false
    end

    it 'adds the Users with the given teacher_ids to the Course' do
      expect do
        post teachers_admin_course_url(course.id), params: { teacher_ids: [ user_1.id, user_2.id ] }
      end.to  change { CourseMembership::Models::Teacher.count }.by(2)
         .and change { UserIsCourseTeacher[course: course, user: user_1] }.to(true)
         .and change { UserIsCourseTeacher[course: course, user: user_2] }.to(true)
    end
  end

  context '#destroy/#restore' do
    let!(:teacher)           { AddUserAsCourseTeacher[user: user_1, course: course].teacher }
    let!(:teacher_student_1) do
      CreateOrResetTeacherStudent[user: user_1, period: period].teacher_student
    end
    let!(:teacher_student_2) do
      CreateOrResetTeacherStudent[user: user_1, period: period].teacher_student
    end

    before do
      expect(teacher_student_1.reload.deleted?).to eq true
      expect(teacher_student_2.reload.deleted?).to eq false
    end

    it 'drops a teacher and all of their teacher_students' do
      expect(UserIsCourseTeacher[course: course, user: user_1]).to eq true
      expect(teacher.reload.deleted?).to eq false

      expect do
        delete admin_teacher_url(teacher.id)
      end.to  change     { UserIsCourseTeacher[course: course, user: user_1] }.to(false)
         .and change     { teacher.reload.deleted? }.to(true)
         .and not_change { teacher_student_1.reload.deleted? }
         .and change     { teacher_student_2.reload.deleted? }.to(true)

      expect(response).to redirect_to edit_admin_course_url(course, anchor: 'teachers')
    end

    it 'restores a teacher but not their teacher_students' do
      teacher.destroy!
      expect(UserIsCourseTeacher[course: course, user: user_1]).to eq false
      expect(teacher.reload.deleted?).to eq true

      expect do
        put restore_admin_teacher_url(teacher.id)
      end.to  change     { UserIsCourseTeacher[course: course, user: user_1] }.to(true)
         .and change     { teacher.reload.deleted? }.to(false)
         .and not_change { teacher_student_1.reload.deleted? }
         .and not_change { teacher_student_2.reload.deleted? }

      expect(response).to redirect_to edit_admin_course_url(course, anchor: 'teachers')
    end
  end
end
