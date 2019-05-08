require 'rails_helper'
require 'vcr_helper'
require 'database_cleaner'

RSpec.describe Api::V1::GuidesController, type: :controller, api: true,
                                          version: :v1, vcr: VCR_OPTS do
  let(:user_1)              { FactoryBot.create(:user) }
  let(:user_1_token)        { FactoryBot.create :doorkeeper_access_token,
                                                 resource_owner_id: user_1.id }

  let(:user_2)              { FactoryBot.create(:user) }
  let(:user_2_token)        { FactoryBot.create :doorkeeper_access_token,
                                                 resource_owner_id: user_2.id }

  let(:course)              { FactoryBot.create :course_profile_course }
  let(:period)              { FactoryBot.create :course_membership_period, course: course }

  context 'Learning guides' do
    let!(:teacher_role)     do
      AddUserAsCourseTeacher.call(course: course, user: user_1).outputs[:role]
    end

    let(:course_guide)      { Hashie::Mash.new(title: 'Title', page_ids: [1], children: []) }

    context '#student' do
      let!(:student_role)   {
        AddUserAsPeriodStudent.call(period: period, user: user_2).outputs[:role]
      }

      let(:user_3)          { FactoryBot.create(:user) }

      let!(:student_3_role) {
        AddUserAsPeriodStudent.call(period: period, user: user_3).outputs[:role]
      }

      it 'returns the student guide for the logged in user' do
        expect(GetStudentGuide).to receive(:[]).with(role: student_role).and_return(course_guide)

        api_get :student, user_2_token, parameters: { course_id: course.id }
      end

      it 'raises SecurityTransgression if the student has been dropped' do
        student_role.student.destroy

        expect do
          api_get :student, user_2_token, parameters: { course_id: course.id }
        end.to raise_error(SecurityTransgression)
      end

      it 'raises SecurityTransgression if the period has been archived' do
        period.destroy

        expect do
          api_get :student, user_2_token, parameters: { course_id: course.id }
        end.to raise_error(SecurityTransgression)
      end

      it "returns 422 if needs to pay" do
        make_payment_required_and_expect_422(course: course, student: student_role.student) {
          api_get :student, user_2_token, parameters: { course_id: course.id }
        }
      end
    end

    context '#teacher' do
      it 'returns the teacher guide' do
        expect(GetTeacherGuide).to receive(:[]).with(role: teacher_role).and_return([course_guide])

        api_get :teacher, user_1_token, parameters: { course_id: course.id }
      end

      it 'raises SecurityTransgression if the teacher was deleted' do
        teacher_role.teacher.destroy

        expect do
          api_get :teacher, user_1_token, parameters: { course_id: course.id }
        end.to raise_error(SecurityTransgression)
      end
    end
  end
end
