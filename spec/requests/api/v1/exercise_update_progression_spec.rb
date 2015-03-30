require 'rails_helper'

RSpec.describe "Exercise update progression", type: :request, :api => true, :version => :v1 do

  let!(:application)     { FactoryGirl.create :doorkeeper_application }
  let!(:user_1)          { FactoryGirl.create :user }
  let!(:user_1_token)    { FactoryGirl.create :doorkeeper_access_token,
                                              application: application,
                                              resource_owner_id: user_1.id }

  let!(:tasked) { FactoryGirl.create(:tasks_tasked_exercise,
                                     :with_tasking, tasked_to: user_1) }

  let!(:step_route_base) { "/api/steps/#{tasked.task_step.id}" }

  it "only shows feedback and correct answer id after completed" do

    api_get(step_route_base, user_1_token)

    expect(response.body_as_hash).not_to have_key(:feedback_html)
    expect(response.body_as_hash).not_to have_key(:correct_answer_id)

    tasked.free_response = 'abcdefg'
    tasked.save!

    api_get(step_route_base, user_1_token)

    expect(response.body_as_hash).not_to have_key(:feedback_html)
    expect(response.body_as_hash).not_to have_key(:correct_answer_id)

    tasked.answer_id = tasked.correct_answer_id
    tasked.save!

    api_get(step_route_base, user_1_token)

    expect(response.body_as_hash).not_to have_key(:feedback_html)
    expect(response.body_as_hash).not_to have_key(:correct_answer_id)

    # Mark it as complete and then get it again (PUT returns No Content)
    api_put("#{step_route_base}/completed", user_1_token)
    api_get(step_route_base, user_1_token)

    expect(response.body_as_hash).to include(feedback_html: 'Right!')
    expect(response.body_as_hash).to include(
      correct_answer_id: tasked.correct_answer_id
    )
  end

  it "does not allow the answer to be changed after completed" do
    api_put("#{step_route_base}", user_1_token,
            raw_post_data: {free_response: 'abcdef'}.to_json)
    expect(response).to have_http_status(:success)

    tasked.reload
    expect(tasked.free_response).to eq 'abcdef'

    api_put("#{step_route_base}", user_1_token,
            raw_post_data: {answer_id: tasked.answers[0][1]['id']}.to_json)
    expect(response).to have_http_status(:success)

    tasked.reload
    expect(tasked.answer_id).to eq tasked.answers[0][1]['id']

    # Mark it as complete and then get it again (PUT returns No Content)
    api_put("#{step_route_base}/completed", user_1_token)

    tasked.reload
    expect(tasked.completed?).to eq true

    api_put("#{step_route_base}", user_1_token,
            raw_post_data: {free_response: 'I changed my mind!'}.to_json)
    expect(response).to have_http_status(:unprocessable_entity)

    tasked.reload
    expect(tasked.free_response).to eq 'abcdef'

    api_put("#{step_route_base}", user_1_token,
            raw_post_data: {answer_id: tasked.answers[0][0]['id']}.to_json)
    expect(response).to have_http_status(:unprocessable_entity)

    tasked.reload
    expect(tasked.answer_id).to eq tasked.answers[0][1]['id']
  end

end



