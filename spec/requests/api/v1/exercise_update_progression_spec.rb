require 'rails_helper'

RSpec.describe 'Exercise update progression', type: :request, api: true, version: :v1 do
  let(:application)     { FactoryBot.create :doorkeeper_application }
  let(:user_1)          { FactoryBot.create(:user_profile) }
  let(:user_1_token)    do
    FactoryBot.create :doorkeeper_access_token, application: application,
                                                resource_owner_id: user_1.id
  end

  let(:tasked) do
    FactoryBot.create :tasks_tasked_exercise, :with_tasking,
                                              tasked_to: Role::GetDefaultUserRole[user_1]
  end

  let(:grading_template) { tasked.task_step.task.task_plan.grading_template }

  let(:step_route_base) { "/api/steps/#{tasked.task_step.id}" }

  before { grading_template.update_column :auto_grading_feedback_on, :due }

  it "only shows feedback and correct answer id after completed and feedback available" do
    api_get(step_route_base, user_1_token)

    expect(response.body_as_hash).not_to have_key(:solution)
    expect(response.body_as_hash).not_to have_key(:feedback_html)
    expect(response.body_as_hash).not_to have_key(:correct_answer_id)

    tasked.free_response = 'abcdefg'
    tasked.save!

    api_get(step_route_base, user_1_token)

    expect(response.body_as_hash).not_to have_key(:solution)
    expect(response.body_as_hash).not_to have_key(:feedback_html)
    expect(response.body_as_hash).not_to have_key(:correct_answer_id)

    correct_answer_id = tasked.correct_answer_id
    tasked.answer_id = correct_answer_id
    tasked.save!

    api_get(step_route_base, user_1_token)

    expect(response.body_as_hash).not_to have_key(:solution)
    expect(response.body_as_hash).not_to have_key(:feedback_html)
    expect(response.body_as_hash).not_to have_key(:correct_answer_id)

    # save it and then get it again
    api_put("#{step_route_base}", user_1_token)

    expect(response.body_as_hash).not_to have_key(:solution)
    expect(response.body_as_hash).not_to have_key(:feedback_html)
    expect(response.body_as_hash).not_to have_key(:correct_answer_id)

    api_get(step_route_base, user_1_token)

    expect(response.body_as_hash).not_to have_key(:solution)
    expect(response.body_as_hash).not_to have_key(:feedback_html)
    expect(response.body_as_hash).not_to have_key(:correct_answer_id)

    # Get it again after feedback is available
    grading_template.update_column :auto_grading_feedback_on, :answer

    api_get(step_route_base, user_1_token)

    expect(response.body_as_hash).to include(solution: { content_html: "The first one." })
    expect(response.body_as_hash).to include(feedback_html: 'Right!')

    expect(response.body_as_hash).to include(correct_answer_id: correct_answer_id)
  end

  it "does not allow the answer to be changed after completed and feedback is available" do
    # Initial submission of multiple choice and free response
    answer_id = tasked.answer_ids.first
    api_put("#{step_route_base}", user_1_token,
            params: { free_response: 'My first answer', answer_id: answer_id }.to_json)
    expect(response).to have_http_status(:success)

    tasked.reload
    expect(tasked.answer_id).to eq answer_id
    expect(tasked.free_response).to eq 'My first answer'

    # No feedback yet
    expect(response.body_as_hash).not_to include(:solution)
    expect(response.body_as_hash).not_to include(:correct_answer_id)
    expect(response.body_as_hash).not_to include(:feedback_html)

    tasked.reload
    expect(tasked.completed?).to eq true

    # Feedback date has not passed, so the answer can still be updated
    api_put("#{step_route_base}", user_1_token,
            params: { free_response: 'Something else!' }.to_json)
    expect(response).to have_http_status(:success)

    # Feedback is now available
    grading_template.update_column :auto_grading_feedback_on, :answer

    # Free response cannot be changed
    api_put("#{step_route_base}", user_1_token,
            params: { free_response: 'I changed my mind!' }.to_json)
    expect(response).to have_http_status(:unprocessable_entity)

    tasked.reload
    expect(tasked.free_response).to eq 'Something else!'

    # Multiple choice cannot be changed
    new_answer_id = tasked.answer_ids.last
    expect(new_answer_id).not_to eq tasked.answer_id

    api_put("#{step_route_base}", user_1_token,
            params: { answer_id: new_answer_id }.to_json)
    expect(response).to have_http_status(:unprocessable_entity)

    tasked.reload
    expect(tasked.answer_id).to eq answer_id
  end
end
