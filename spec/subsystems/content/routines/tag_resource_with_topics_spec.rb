require 'rails_helper'

RSpec.describe Content::TagResourceWithTopics, :type => :routine do
  let!(:topic_1) { FactoryGirl.create :content_topic }
  let!(:topic_2) { FactoryGirl.create :content_topic }

  [:content_page, :content_exercise].each do |resource_class|
    subject(:resource) { FactoryGirl.create resource_class }

    let!(:tag_method_name) { "#{resource_class}_topics" }

    it "assigns the given Topics to the given #{
         resource_class.to_s.capitalize
       }" do

      result = nil
      expect {
        result = Content::TagResourceWithTopics.call(resource, [topic_1, topic_2.name])
      }.to change{ resource.send(tag_method_name).count }.by(2)
      expect(result.errors).to be_empty

      resource.reload
      expect(resource.send(tag_method_name).collect{|t| t.content_topic}).to(
        eq [topic_1, topic_2])
    end
  end
end
