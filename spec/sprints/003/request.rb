require 'rails_helper'

RSpec.describe "Sprint 3 API", type: :request, :api => true, :version => :v1 do

  let!(:application)     { FactoryGirl.create :doorkeeper_application }
  let!(:jimmy)           { FactoryGirl.create :user }
  let!(:jimmy_token)     { FactoryGirl.create :doorkeeper_access_token, 
                                              application: application, 
                                              resource_owner_id: jimmy.id }

  it "produces the correct user tasks JSON" do
    open_time = Time.now
    Sprint003::Main.call(username_or_user: jimmy, opens_at: open_time)

    get '/api/user/tasks', 
        {format: :json}, 
        {'HTTP_AUTHORIZATION' => "Bearer #{jimmy_token.token}", 
         'HTTP_ACCEPT' => "application/vnd.tutor.openstax.v1"}

    expect(response.code).to eq('200'); debugger
    expect(response.body).to eq({
      total_count: 1,
      items: [
        {
          id: 1,
          title: "Reading",
          task_plan_id: 1,
          opens_at: open_time.to_formatted_s(:w3cz),
          is_shared: false,
          steps: [
            {
              id: 1,
              type: "reading",
              title: "TODO get this from module",
              content_url: "http://archive.cnx.org/contents/3e1fc4c6-b090-47c1-8170-8578198cc3f0@8.html"
            }
          ]
        }
      ]
    }.to_json)
  end



end



