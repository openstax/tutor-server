require 'rails_helper'

RSpec.describe SendTaskedExerciseAnswerToExchange, type: :routine do
  let(:exchange_identifier) { '42' }
  let(:free_response)       { 'abc' }

  let(:period)             { FactoryGirl.create :course_membership_period }
  let(:user)               { FactoryGirl.create :user,
                                         exchange_write_identifier: exchange_identifier }
  let(:role)               { AddUserAsPeriodStudent[user: user, period: period] }
  let(:tasked_exercise)    { FactoryGirl.create :tasks_tasked_exercise,
                                                 :with_tasking,
                                                 tasked_to: role,
                                                 free_response: free_response }
  let(:answer_id)          { tasked_exercise.correct_answer_id }

  before(:each) do
    tasked_exercise.update_attribute(:answer_id, answer_id)
  end

  it 'records answers and grade in exchange when the task_step is completed' do
    expect(OpenStax::Exchange).to receive(:record_multiple_choice_answer)
                                    .with(exchange_identifier,
                                          tasked_exercise.url,
                                          tasked_exercise.task_step.id.to_s,
                                          answer_id)
    expect(OpenStax::Exchange).to receive(:record_grade)
                                    .with(exchange_identifier,
                                          tasked_exercise.url,
                                          tasked_exercise.task_step.id.to_s,
                                          1,
                                          'tutor')
    described_class[tasked_exercise: tasked_exercise]
  end
end
