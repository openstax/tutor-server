require 'rails_helper'

RSpec.describe SendTaskedExerciseAnswerToExchange, type: :routine do
  let!(:tasked_exercise)    { FactoryGirl.create(:tasks_tasked_exercise, free_response: 'abc') }

  let(:exchange_identifier) { 42 }
  let(:answer_id)           { tasked_exercise.correct_answer_id }
  let(:free_response)

  it 'records answers and grade in exchange when the task_step is completed' do
    roles = tasked_exercise.task_step.task.taskings.collect{ |tasking| tasking.role }
    users = Role::GetUsersForRoles[roles]
    users.each{ |user| allow(user).to receive(:identifier).and_return(exchange_identifier) }

    tasked_exercise.answer_id = answer_id
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
