require 'rails_helper'
require 'tasks/sprint/sprint_006/beta'

RSpec.describe "Sprint006::Beta", :type => :request do

  let!(:application)     { FactoryGirl.create :doorkeeper_application }

  it "doesn't catch on fire" do
    Sprint006::Beta.call(username_or_user: "frank")

    frank = User.last
    frank_token = FactoryGirl.create :doorkeeper_access_token, 
                                     application: application, 
                                     resource_owner_id: frank.id

    request(:get, "/api/tasks/#{Task.first.id}", frank_token)

    expect(response).to have_http_status(:success)

    step = response.body_as_hash[:steps][1]

    expect(step).not_to have_key(:correct_answer_id)
    expect(step).not_to have_key(:feedback_html)
    expect(step).to include(is_completed: false)

    request(:put, "/api/tasks/#{Task.first.id}/steps/#{step[:id]}/completed", frank_token)

    expect(response).to have_http_status(:success)

    request(:get, "/api/tasks/#{Task.first.id}", frank_token)

    step = response.body_as_hash[:steps][1]
    expect(step).to include(is_completed: true)

    expect(step).to have_key(:correct_answer_id)
    expect(step).to have_key(:feedback_html)    
  end

  # TODO I copied this code b/c it is uber late; but where should it go?
  def request(type, route, token=nil)
    http_header = {}
    http_header['HTTP_AUTHORIZATION'] = "Bearer #{token.token}" if token.present?
    http_header['HTTP_ACCEPT'] = "application/vnd.tutor.openstax.v1"

    send(type, route, {format: :json}, http_header)
  end

end



