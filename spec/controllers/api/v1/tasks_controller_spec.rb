require "rails_helper"

module Api::V1
  RSpec.describe TasksController, :type => :controller, :api => true, :version => :v1 do

    let!(:application)     { FactoryGirl.create :doorkeeper_application }
    let!(:user_1)          { FactoryGirl.create :user }
    let!(:user_1_token)    { FactoryGirl.create :doorkeeper_access_token, 
                                                application: application, 
                                                resource_owner_id: user_1.id }

    pending "add some examples to #{__FILE__}"
  end
end
