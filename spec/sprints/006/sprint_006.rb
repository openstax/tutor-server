require 'rails_helper'

RSpec.describe Sprint006, :type => :routine do

  let!(:application)     { FactoryGirl.create :doorkeeper_application }
  let!(:jimmy)           { FactoryGirl.create :user }
  let!(:jimmy_token)     { FactoryGirl.create :doorkeeper_access_token, 
                                              application: application, 
                                              resource_owner_id: jimmy.id }

  it "doesn't catch on fire" do
    result = Sprint006::Main.call("frank")
  end

end



