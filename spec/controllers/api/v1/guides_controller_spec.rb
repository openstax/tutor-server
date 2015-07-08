require 'rails_helper'
require 'vcr_helper'
require 'database_cleaner'

RSpec.describe Api::V1::GuidesController, type: :controller, api: true,
                                          version: :v1, vcr: VCR_OPTS do
  let!(:user_1)          { FactoryGirl.create :user_profile }
  let!(:user_1_token)    { FactoryGirl.create :doorkeeper_access_token,
                                              resource_owner_id: user_1.id }

  let!(:user_2)          { FactoryGirl.create :user_profile }
  let!(:user_2_token)    { FactoryGirl.create :doorkeeper_access_token,
                                              resource_owner_id: user_2.id }

  let!(:course) { CreateCourse[name: 'Physics 101'] }
  let!(:period) { CreatePeriod[course: course] }

  describe 'Learning guides' do
    let!(:teacher_role) {
      AddUserAsCourseTeacher.call(course: course,
                                  user: user_1.entity_user).outputs[:role]
    }

    let!(:course_guide) {
      Hashie::Mash.new(title: 'Title', page_ids: [1], children: [])
    }

    let!(:get_course_guide) { class_double(GetCourseGuide).as_stubbed_const }

    describe '#student' do
      let!(:student_role) {
        AddUserAsPeriodStudent.call(period: period,
                                    user: user_2.entity_user).outputs[:role]
      }

      let!(:user_3) { FactoryGirl.create :user_profile }

      let!(:student_3_role) {
        AddUserAsPeriodStudent.call(period: period,
                                    user: user_3.entity_user).outputs[:role]
      }

      it 'returns the student guide for the logged in user' do
        expect(get_course_guide).to receive(:[])
                                    .with(role: student_role, course: course)
                                    .and_return(course_guide)

        api_get :student, user_2_token, parameters: { id: course.id }
      end

      it 'returns the student guide for a teacher providing a student role ID' do
        expect(get_course_guide).to receive(:[])
                                    .with(role: student_3_role, course: course)
                                    .and_return(course_guide)

        api_get :student, user_1_token, parameters: { id: course.id,
                                                             role_id: student_3_role.id }
      end
    end

    describe '#teacher' do
      it 'returns the teacher guide' do
        expect(get_course_guide).to receive(:[])
                                    .with(role: teacher_role, course: course)
                                    .and_return(course_guide)

        api_get :teacher, user_1_token, parameters: { id: course.id }
      end
    end
  end
end
