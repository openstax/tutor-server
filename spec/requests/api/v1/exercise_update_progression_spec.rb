require 'rails_helper'

RSpec.describe "Exercise update progression", type: :request, :api => true, :version => :v1 do

  let!(:application)     { FactoryGirl.create :doorkeeper_application }
  let!(:user_1)          { FactoryGirl.create :user }
  let!(:user_1_token)    { FactoryGirl.create :doorkeeper_access_token,
                                              application: application,
                                              resource_owner_id: user_1.id }

  let!(:tasked) { FactoryGirl.create(:tasked_exercise, 
                                     :with_tasking, tasked_to: user_1) }

  let!(:step_route_base) { "/api/tasks/#{tasked.task_step.task.id}/steps/#{tasked.task_step.id}" }

  it "only shows feedback and correct answer id after complete" do

    api_get(step_route_base, user_1_token)

    expect(response.body_as_hash).not_to have_key(:feedback_html)
    expect(response.body_as_hash).not_to have_key(:correct_answer_id)

    # TODO: This "completed" route is odd.
    #       An Exercise should be "complete" when it is answered?
    tasked.answer_id = tasked.correct_answer_id
    tasked.save!

    # Mark it as complete and then get it again (PUT returns No Content)
    api_put("#{step_route_base}/completed", user_1_token)
    api_get(step_route_base, user_1_token)

    expect(response.body_as_hash).to include(feedback_html: 'Right!')
    expect(response.body_as_hash).to include(
      correct_answer_id: tasked.correct_answer_id
    )
  end

end



