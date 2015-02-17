require 'rails_helper'
require 'tasks/sprint/sprint_006/main'

RSpec.describe "Sprint 6 API", type: :request, :api => true, :version => :v1 do

  let!(:application)     { FactoryGirl.create :doorkeeper_application }
  let!(:jimmy)           { FactoryGirl.create :user }
  let!(:jimmy_token)     { FactoryGirl.create :doorkeeper_access_token, 
                                              application: application, 
                                              resource_owner_id: jimmy.id }

  it "ponders life" do
    # put some smoke tests here, see sprint 003
  end

end



