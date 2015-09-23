require 'rails_helper'

RSpec.describe Admin::StudentsController do
  let!(:admin) {
    profile = FactoryGirl.create(:user_profile, :administrator)
    strategy = User::Strategies::Direct::User.new(profile)
    User::User.new(strategy: strategy)
  }

  before { controller.sign_in(admin) }

  describe 'GET #index' do
    let!(:course) { CreateCourse[name: 'Physics'] }
    let!(:course_2) { CreateCourse[name: 'Biology'] }

    let!(:periods) { [
      CreatePeriod[course: course],
      CreatePeriod[course: course]
    ] }
    let!(:periods_2) { [CreatePeriod[course: course_2]] }

    let!(:user_1) {
      profile = FactoryGirl.create(:user_profile, username: 'benjamin')
      strategy = User::Strategies::Direct::User.new(profile)
      User::User.new(strategy: strategy)
    }
    let!(:user_2) {
      profile = FactoryGirl.create(:user_profile, username: 'nikolai')
      strategy = User::Strategies::Direct::User.new(profile)
      User::User.new(strategy: strategy)
    }
    let!(:user_3) {
      profile = FactoryGirl.create(:user_profile, username: 'freja')
      strategy = User::Strategies::Direct::User.new(profile)
      User::User.new(strategy: strategy)
    }
    let!(:user_4) {
      profile = FactoryGirl.create(:user_profile, username: 'oskar')
      strategy = User::Strategies::Direct::User.new(profile)
      User::User.new(strategy: strategy)
    }

    let!(:student_1) {
      AddUserAsPeriodStudent.call(user: user_1, period: periods[0]).outputs.student
    }
    let!(:student_2) {
      AddUserAsPeriodStudent.call(user: user_2, period: periods[0]).outputs.student
    }
    let!(:student_3) {
      AddUserAsPeriodStudent.call(user: user_3, period: periods[1]).outputs.student
    }
    let!(:student_4) {
      AddUserAsPeriodStudent.call(user: user_4, period: periods_2[0]).outputs.student
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
