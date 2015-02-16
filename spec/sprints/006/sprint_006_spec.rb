require 'rails_helper'
require 'tasks/sprint/sprint_006/main'

RSpec.describe Sprint006, :type => :routine do

  let!(:application)     { FactoryGirl.create :doorkeeper_application }
  let!(:jimmy)           { FactoryGirl.create :user }
  let!(:jimmy_token)     { FactoryGirl.create :doorkeeper_access_token, 
                                              application: application, 
                                              resource_owner_id: jimmy.id }

  it "doesn't catch on fire" do
    expect(Sprint006::Main.call(username_or_user: "frank").errors).to be_empty
  end

end



