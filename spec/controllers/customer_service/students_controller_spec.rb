require 'rails_helper'

RSpec.describe CustomerService::StudentsController do
  let(:customer_service) { FactoryBot.create(:user, :customer_service) }

  before                 { controller.sign_in(customer_service) }

  describe 'GET #index' do
    let(:course)     { FactoryBot.create :course_profile_course, name: 'Physics' }
    let(:course_2)   { FactoryBot.create :course_profile_course }

    let(:periods)    do
      [
        FactoryBot.create(:course_membership_period, course: course),
        FactoryBot.create(:course_membership_period, course: course)
      ]
    end
    let(:periods_2)  { [FactoryBot.create(:course_membership_period, course: course_2)] }

    let(:user_1)     { FactoryBot.create(:user, first_name: 'Benjamin', last_name: 'Franklin') }
    let(:user_2)     { FactoryBot.create(:user, first_name: 'Nikola', last_name: 'Tesla') }
    let(:user_3)     { FactoryBot.create(:user, first_name: 'Freja', last_name: 'Asgard') }
    let(:user_4)     { FactoryBot.create(:user, first_name: 'Oliver', last_name: 'Wilde') }

    let!(:student_1) do
      AddUserAsPeriodStudent.call(user: user_1, period: periods[0]).outputs.student
    end
    let!(:student_2) do
      AddUserAsPeriodStudent.call(user: user_2, period: periods[0]).outputs.student
    end
    let!(:student_3) do
      AddUserAsPeriodStudent.call(user: user_3, period: periods[1]).outputs.student
    end
    let!(:student_4) do
      AddUserAsPeriodStudent.call(user: user_4, period: periods_2[0]).outputs.student
    end

    it 'returns all the students in a course' do
      get :index, course_id: course.id
      expect(assigns[:course].name).to eq 'Physics'
      expect(assigns[:students]).to eq [ student_1, student_3, student_2 ]
    end

    it 'works even if a student has a nil username' do
      user_2.account.update_attribute :username, nil

      get :index, course_id: course.id
      expect(assigns[:course].name).to eq 'Physics'
      expect(assigns[:students]).to eq [ student_1, student_3, student_2 ]
    end
  end
end
