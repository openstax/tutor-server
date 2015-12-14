require 'rails_helper'

RSpec.describe Admin::StudentsController do
  let!(:admin) { FactoryGirl.create(:user, :administrator) }

  before { controller.sign_in(admin) }

  describe 'GET #index' do
    let!(:course) { CreateCourse.call(name: 'Physics').course }
    let!(:course_2) { CreateCourse.call(name: 'Biology').course }

    let!(:periods) { [
      CreatePeriod.call(course: course),
      CreatePeriod.call(course: course)
    ] }
    let!(:periods_2) { [CreatePeriod.call(course: course_2)] }

    let!(:user_1) { FactoryGirl.create(:user, username: 'benjamin') }
    let!(:user_2) { FactoryGirl.create(:user, username: 'nicolai') }
    let!(:user_3) { FactoryGirl.create(:user, username: 'freja') }
    let!(:user_4) { FactoryGirl.create(:user, username: 'oskar') }

    let!(:student_1) {
      AddUserAsPeriodStudent.call(user: user_1, period: periods[0]).student
    }
    let!(:student_2) {
      AddUserAsPeriodStudent.call(user: user_2, period: periods[0]).student
    }
    let!(:student_3) {
      AddUserAsPeriodStudent.call(user: user_3, period: periods[1]).student
    }
    let!(:student_4) {
      AddUserAsPeriodStudent.call(user: user_4, period: periods_2[0]).student
    }

    it 'returns all the students in a course' do
      get :index, course_id: course.id
      expect(assigns[:course].name).to eq 'Physics'
      expect(assigns[:students]).to eq([
        {
          'id' => student_1.id,
          'username' => 'benjamin',
          'first_name' => user_1.first_name,
          'last_name' => user_1.last_name,
          'name' => user_1.name,
          'entity_role_id' => student_1.entity_role_id,
          'course_membership_period_id' => student_1.period.id,
          'deidentifier' => student_1.deidentifier,
          'active?' => true
        },
        {
          'id' => student_3.id,
          'username' => 'freja',
          'first_name' => user_3.first_name,
          'last_name' => user_3.last_name,
          'name' => user_3.name,
          'entity_role_id' => student_3.entity_role_id,
          'course_membership_period_id' => student_3.period.id,
          'deidentifier' => student_3.deidentifier,
          'active?' => true
        },
        {
          'id' => student_2.id,
          'username' => 'nicolai',
          'first_name' => user_2.first_name,
          'last_name' => user_2.last_name,
          'name' => user_2.name,
          'entity_role_id' => student_2.entity_role_id,
          'course_membership_period_id' => student_2.period.id,
          'deidentifier' => student_2.deidentifier,
          'active?' => true
        }
      ])
    end
  end
end
