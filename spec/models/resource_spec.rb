require 'rails_helper'

RSpec.describe Resource, :type => :model do
  subject(:resource) { FactoryGirl.create :resource }

  it { is_expected.to have_one(:page).dependent(:destroy) }
  it { is_expected.to have_one(:exercise).dependent(:destroy) }
  it { is_expected.to have_one(:interactive).dependent(:destroy) }

  it { is_expected.to validate_presence_of(:url) }

  it { is_expected.to validate_uniqueness_of(:url) }

  xit 'returns cached content if available' do
  end

  xit 'retrieves and caches content if not cached or expired' do
  end

  it 'knows its own topics' do
    topic_1 = FactoryGirl.create(:resource_topic, resource: resource).topic
    topic_2 = FactoryGirl.create(:resource_topic, resource: resource).topic

    resource.reload
    expect(resource.topics).to eq [topic_1, topic_2]
  end
end
