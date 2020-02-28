require 'rails_helper'

RSpec.describe CustomerService::StudentsController, type: :controller do
  let(:customer_service) { FactoryBot.create(:user_profile, :customer_service) }

  before                 { controller.sign_in(customer_service) }

  context 'GET #index' do
    let(:course)     { FactoryBot.create :course_profile_course, name: 'Physics' }
    let(:course_2)   { FactoryBot.create :course_profile_course }

    let(:periods)    do
      [
        FactoryBot.create(:course_membership_period, course: course),
        FactoryBot.create(:course_membership_period, course: course)
      ]
    end
    let(:periods_2)  { [FactoryBot.create(:course_membership_period, course: course_2)] }

    let(:user_1)     { FactoryBot.create(:user_profile, first_name: 'Benjamin', last_name: 'Franklin') }
    let(:user_2)     { FactoryBot.create(:user_profile, first_name: 'Nikola', last_name: 'Tesla') }
    let(:user_3)     { FactoryBot.create(:user_profile, first_name: 'Freja', last_name: 'Asgard') }
    let(:user_4)     { FactoryBot.create(:user_profile, first_name: 'Oliver', last_name: 'Wilde') }

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
      get :index, params: { course_id: course.id }
      expect(assigns[:course].name).to eq 'Physics'
      expect(assigns[:students]).to match a_collection_containing_exactly(
        a_hash_including(
          'id' => student_1.id,
          'username' => user_1.username,
          'first_name' => user_1.first_name,
          'last_name' => user_1.last_name,
          'name' => user_1.name,
          'entity_role_id' => student_1.entity_role_id,
          'course_membership_period_id' => student_1.period.id,
          'student_identifier' => student_1.student_identifier,
          'dropped?' => false
        ),
        a_hash_including(
          'id' => student_3.id,
          'username' => user_3.username,
          'first_name' => user_3.first_name,
          'last_name' => user_3.last_name,
          'name' => user_3.name,
          'entity_role_id' => student_3.entity_role_id,
          'course_membership_period_id' => student_3.period.id,
          'student_identifier' => student_3.student_identifier,
          'dropped?' => false
        ),
        a_hash_including(
          'id' => student_2.id,
          'username' => user_2.username,
          'first_name' => user_2.first_name,
          'last_name' => user_2.last_name,
          'name' => user_2.name,
          'entity_role_id' => student_2.entity_role_id,
          'course_membership_period_id' => student_2.period.id,
          'student_identifier' => student_2.student_identifier,
          'dropped?' => false
        )
      )
    end

    it 'works even if a student has a nil username' do
      user_2.account.update_attribute :username, nil

      get :index, params: { course_id: course.id }
      expect(assigns[:course].name).to eq 'Physics'
      expect(assigns[:students]).to match a_collection_containing_exactly(
        a_hash_including(
          'id' => student_1.id,
          'username' => user_1.username,
          'first_name' => user_1.first_name,
          'last_name' => user_1.last_name,
          'name' => user_1.name,
          'entity_role_id' => student_1.entity_role_id,
          'course_membership_period_id' => student_1.period.id,
          'student_identifier' => student_1.student_identifier,
          'dropped?' => false
        ),
        a_hash_including(
          'id' => student_3.id,
          'username' => user_3.username,
          'first_name' => user_3.first_name,
          'last_name' => user_3.last_name,
          'name' => user_3.name,
          'entity_role_id' => student_3.entity_role_id,
          'course_membership_period_id' => student_3.period.id,
          'student_identifier' => student_3.student_identifier,
          'dropped?' => false
        ),
        a_hash_including(
          'id' => student_2.id,
          'username' => nil,
          'first_name' => user_2.first_name,
          'last_name' => user_2.last_name,
          'name' => user_2.name,
          'entity_role_id' => student_2.entity_role_id,
          'course_membership_period_id' => student_2.period.id,
          'student_identifier' => student_2.student_identifier,
          'dropped?' => false
        )
      )
    end
  end
end
