require 'rails_helper'

RSpec.describe "Exercise update progression", type: :request, :api => true, :version => :v1 do

  let!(:application)     { FactoryGirl.create :doorkeeper_application }
  let!(:user_1)          { FactoryGirl.create :user_profile }
  let!(:user_1_token)    { FactoryGirl.create :doorkeeper_access_token,
                                              application: application,
                                              resource_owner_id: user_1.id }

  let!(:tasked) { FactoryGirl.create(:tasks_tasked_exercise,
                                     :with_tasking,
                                     tasked_to: Role::GetDefaultUserRole[user_1.entity_user]) }

  let!(:step_route_base) { "/api/steps/#{tasked.task_step.id}" }

  it "only shows feedback and correct answer id after completed and feedback available" do

    api_get(step_route_base, user_1_token)

    expect(response.body_as_hash).not_to have_key(:feedback_html)
    expect(response.body_as_hash).not_to have_key(:correct_answer_id)

    tasked.free_response = 'abcdefg'
    tasked.save!

    api_get(step_route_base, user_1_token)

    expect(response.body_as_hash).not_to have_key(:feedback_html)
    expect(response.body_as_hash).not_to have_key(:correct_answer_id)

    correct_answer_id = Exercise.new(tasked.exercise).correct_question_answer_ids[0][0]
    tasked.answer_id = correct_answer_id
    tasked.save!

    api_get(step_route_base, user_1_token)

    expect(response.body_as_hash).not_to have_key(:feedback_html)
    expect(response.body_as_hash).not_to have_key(:correct_answer_id)

    # Mark it as complete and then get it again
    api_put("#{step_route_base}/completed", user_1_token)

    expect(response.body_as_hash).not_to have_key(:feedback_html)
    expect(response.body_as_hash).not_to have_key(:correct_answer_id)

    api_get(step_route_base, user_1_token)

    expect(response.body_as_hash).not_to have_key(:feedback_html)
    expect(response.body_as_hash).not_to have_key(:correct_answer_id)

    # Get it again after feedback is available
    tasked.task_step.task.feedback_at = Time.now
    tasked.task_step.task.save!

    api_get(step_route_base, user_1_token)

    expect(response.body_as_hash).to include(feedback_html: 'Right!')
    expect(response.body_as_hash).to include(correct_answer_id: correct_answer_id)
  end

  it "does not allow the answer to be changed after completed" do
    api_put("#{step_route_base}", user_1_token,
            raw_post_data: {free_response: 'abcdef'}.to_json)
    expect(response).to have_http_status(:success)

    tasked.reload
    expect(tasked.free_response).to eq 'abcdef'

    answer_id = Exercise.new(tasked.exercise).question_answers[0][1]['id']
    api_put("#{step_route_base}", user_1_token,
            raw_post_data: {answer_id: answer_id}.to_json)
    expect(response).to have_http_status(:success)

    tasked.reload
    expect(tasked.answer_id).to eq answer_id

    # Mark it as complete and then get it again (PUT returns No Content)
    api_put("#{step_route_base}/completed", user_1_token)

    tasked.reload
    expect(tasked.completed?).to eq true

    api_put("#{step_route_base}", user_1_token,
            raw_post_data: {free_response: 'I changed my mind!'}.to_json)
    expect(response).to have_http_status(:unprocessable_entity)

    tasked.reload
    expect(tasked.free_response).to eq 'abcdef'

    new_answer_id = Exercise.new(tasked.exercise).question_answers[0][0]['id']
    api_put("#{step_route_base}", user_1_token,
            raw_post_data: {answer_id: new_answer_id}.to_json)
    expect(response).to have_http_status(:unprocessable_entity)

    tasked.reload
    expect(tasked.answer_id).to eq answer_id
  end

end
