require 'rails_helper'
require 'vcr_helper'

RSpec.describe "PushSalesforceCourseStats", vcr: VCR_OPTS do

  before(:each) { load_salesforce_user }

  it "does it" do
    # Making a call just to test connectivity
    Salesforce::Remote::Opportunity.count
  end

end
