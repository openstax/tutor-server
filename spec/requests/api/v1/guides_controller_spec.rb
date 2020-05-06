require 'rails_helper'
require 'vcr_helper'
require 'database_cleaner'

RSpec.describe Api::V1::GuidesController, type: :request, api: true,
                                          version: :v1, vcr: VCR_OPTS do
  let(:user_1)              { FactoryBot.create(:user_profile) }
  let(:user_1_token)        do
    FactoryBot.create :doorkeeper_access_token, resource_owner_id: user_1.id
  end

  let(:user_2)              { FactoryBot.create(:user_profile) }
  let(:user_2_token)        do
    FactoryBot.create :doorkeeper_access_token, resource_owner_id: user_2.id
  end

  let(:course)              { FactoryBot.create :course_profile_course }
  let(:period)              { FactoryBot.create :course_membership_period, course: course }

  let!(:teacher_role)     do
    AddUserAsCourseTeacher.call(course: course, user: user_1).outputs[:role]
  end

  let(:course_guide)      { Hashie::Mash.new(title: 'Title', page_ids: [1], children: []) }

  context '#student' do
    let!(:student_role)   do
      AddUserAsPeriodStudent.call(period: period, user: user_2).outputs[:role]
    end

    let(:user_3)          { FactoryBot.create(:user_profile) }

    let!(:student_3_role) do
      AddUserAsPeriodStudent.call(period: period, user: user_3).outputs[:role]
    end

    def guide_api_course_path(course_id, role_id: nil)
      url = "/api/courses/#{course_id}/guide"
      role_id.nil? ? url : "#{url}?role_id=#{role_id}"
    end

    it 'returns the student guide for the logged in user' do
      expect(GetStudentGuide).to receive(:[]).with(role: student_role).and_return(course_guide)

      api_get guide_api_course_path(course.id), user_2_token
    end

    it 'returns the student guide for a teacher providing a student role ID' do
      expect(GetStudentGuide).to receive(:[]).with(role: student_3_role).and_return(course_guide)

      api_get guide_api_course_path(course.id, role_id: student_3_role.id), user_1_token
    end

    it 'raises SecurityTransgression if the student has been dropped' do
      student_role.student.destroy

      expect do
        api_get guide_api_course_path(course.id), user_2_token
      end.to raise_error(SecurityTransgression)
    end

    it 'raises SecurityTransgression if the period has been archived' do
      period.destroy

      expect do
        api_get guide_api_course_path(course.id), user_2_token
      end.to raise_error(SecurityTransgression)
    end

    it "returns 422 if needs to pay" do
      make_payment_required_and_expect_422(course: course, student: student_role.student) {
        api_get guide_api_course_path(course.id), user_2_token
      }
    end
  end

  context '#teacher' do
    def teacher_guide_api_course_path(course_id)
      "/api/courses/#{course_id}/teacher_guide"
    end

    it 'returns the teacher guide' do
      expect(GetTeacherGuide).to receive(:[]).with(role: teacher_role).and_return([course_guide])

      api_get teacher_guide_api_course_path(course.id), user_1_token
    end

    it 'raises SecurityTransgression if the teacher was deleted' do
      teacher_role.teacher.destroy

      expect do
        api_get teacher_guide_api_course_path(course.id), user_1_token
      end.to raise_error(SecurityTransgression)
    end
  end
end
