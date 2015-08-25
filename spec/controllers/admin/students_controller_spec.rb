require 'rails_helper'

RSpec.describe Admin::StudentsController do
  let!(:admin) { FactoryGirl.create(:user_profile, :administrator) }

  before { controller.sign_in(admin) }

  describe 'GET #index' do
    let!(:course) { CreateCourse[name: 'Physics'] }
    let!(:course_2) { CreateCourse[name: 'Biology'] }

    let!(:periods) { [
      CreatePeriod[course: course],
      CreatePeriod[course: course]
    ] }
    let!(:periods_2) { [CreatePeriod[course: course_2]] }

    let!(:profile_1) {
      FactoryGirl.create(:user_profile, username: 'benjamin')
    }
    let!(:profile_2) {
      FactoryGirl.create(:user_profile, username: 'nicolai')
    }
    let!(:profile_3) {
      FactoryGirl.create(:user_profile, username: 'freja')
    }
    let!(:profile_4) {
      FactoryGirl.create(:user_profile, username: 'oskar')
    }

    let!(:student_1) {
      AddUserAsPeriodStudent.call(user: profile_1.entity_user, period: periods[0]).outputs.student
    }
    let!(:student_2) {
      AddUserAsPeriodStudent.call(user: profile_2.entity_user, period: periods[0]).outputs.student
    }
    let!(:student_3) {
      AddUserAsPeriodStudent.call(user: profile_3.entity_user, period: periods[1]).outputs.student
    }
    let!(:student_4) {
      AddUserAsPeriodStudent.call(user: profile_4.entity_user, period: periods_2[0]).outputs.student
    }

    it 'returns all the students in a course' do
      get :index, course_id: course.id
      expect(assigns[:course].name).to eq 'Physics'
      expect(assigns[:students]).to eq([
        {
          'id' => student_1.id,
          'username' => 'benjamin',
          'first_name' => profile_1.first_name,
          'last_name' => profile_1.last_name,
          'name' => profile_1.name,
          'entity_role_id' => student_1.entity_role_id,
          'course_membership_period_id' => student_1.period.id,
          'name' => profile_1.name,
          'deidentifier' => student_1.deidentifier,
          'active?' => true
        },
        {
          'id' => student_3.id,
          'username' => 'freja',
          'first_name' => profile_3.first_name,
          'last_name' => profile_3.last_name,
          'name' => profile_3.name,
          'entity_role_id' => student_3.entity_role_id,
          'course_membership_period_id' => student_3.period.id,
          'name' => profile_3.name,
          'deidentifier' => student_3.deidentifier,
          'active?' => true
        },
        {
          'id' => student_2.id,
          'username' => 'nicolai',
          'first_name' => profile_2.first_name,
          'last_name' => profile_2.last_name,
          'name' => profile_2.name,
          'entity_role_id' => student_2.entity_role_id,
          'course_membership_period_id' => student_2.period.id,
          'name' => profile_2.name,
          'deidentifier' => student_2.deidentifier,
          'active?' => true
        }
      ])
    end
  end
end
