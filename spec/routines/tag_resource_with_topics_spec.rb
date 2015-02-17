require 'rails_helper'

RSpec.describe TagResourceWithTopics, :type => :routine do
  let!(:resource) { FactoryGirl.create :resource }

  let!(:topic_1) { FactoryGirl.create :topic }
  let!(:topic_2) { FactoryGirl.create :topic }

  it 'assigns the given Topics to the given Resource' do
    result = nil
    expect {
      result = TagResourceWithTopics.call(resource, [topic_1, topic_2.name])
    }.to change{ resource.resource_topics.count }.by(2)

    resource.reload
    expect(resource.topics).to eq [topic_1, topic_2]
  end
end
