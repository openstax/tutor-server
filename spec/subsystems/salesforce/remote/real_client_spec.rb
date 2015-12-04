require 'rails_helper'

RSpec.describe Salesforce::Remote::RealClient do

  it 'raises when there is no SF user' do
    allow(Salesforce::Models::User).to receive(:first) { nil }
    expect{ Salesforce::Remote::RealClient.new }.to raise_error(SalesforceUserMissing)
  end

end
