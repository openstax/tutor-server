require 'rails_helper'

RSpec.describe Interactive, :type => :model do
  it { is_expected.to belong_to(:resource).dependent(:destroy) }
  it { is_expected.to have_one(:task).dependent(:destroy) }
  it { is_expected.to validate_presence_of(:resource) }

  it "should delegate url and content to its resource" do
    reading = FactoryGirl.create(:reading)
    expect(reading.url).to eq reading.resource.url
    expect(reading.content).to eq reading.resource.content
  end
end
