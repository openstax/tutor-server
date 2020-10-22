require 'rails_helper'
require 'vcr_helper'

RSpec.describe Api::V1::PracticeQuestionsController, type: :request, api: true, version: :v1 do
  let(:application)   { FactoryBot.create :doorkeeper_application }
  let(:course)        { FactoryBot.create :course_profile_course }
  let(:period)        { FactoryBot.create :course_membership_period, course: course }
  let(:student_user)  { FactoryBot.create :user_profile }
  let(:student_role)  { AddUserAsPeriodStudent[user: student_user, period: period] }
  let!(:student)      { student_role.student }

  let(:student_token) do
    FactoryBot.create :doorkeeper_access_token, application: application,
                                                resource_owner_id: student_user.id
  end

  let(:user_2)        { FactoryBot.create(:user_profile) }
  let(:user_2_token)  { FactoryBot.create :doorkeeper_access_token, resource_owner_id: user_2.id }

  let!(:practice_question) { FactoryBot.create :tasks_practice_question, role: student_role }

  let(:tasked) do
    FactoryBot.create(:tasks_tasked_exercise, :with_tasking, tasked_to: student_role)
  end

  context 'GET #index' do
    it "fetches the student's saved questions" do
      api_get api_course_practice_questions_url(course_id: course.id), student_token

      expect(response).to be_ok
      questions = JSON.parse(response.body)
      expect(questions.count).to eq 1
      expect(questions.first['id']).to eq practice_question.id
    end
  end

  context 'POST #create' do
    it 'creates a practice question' do
      expect do
        api_post api_course_practice_questions_url(course_id: course.id), student_token, params: {
                   tasked_exercise_id: tasked.id
                 }.to_json
      end.to change { Tasks::Models::PracticeQuestion.count }

      expect(response).to be_created
      question = Tasks::Models::PracticeQuestion.find JSON.parse(response.body)['id']
      expect(question.tasked_exercise.id).to eq tasked.id
      expect(question.role).to eq student_role
    end
  end

  context 'DELETE #destroy' do
    it 'deletes a practice question' do
      api_delete api_course_practice_question_url(course_id: course.id, id: practice_question.id), student_token

      expect(response).to be_ok
      expect { practice_question.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "does not let a user delete someone else's practice question" do
      expect do
        api_delete api_course_practice_question_url(course_id: course.id, id: practice_question.id), user_2_token
      end.to raise_error(SecurityTransgression)
    end
  end
end
