require 'rails_helper'

RSpec.describe Content::Routines::TagResourceWithTopics, :type => :routine do
  let!(:topic_1) { FactoryGirl.create :content_topic }
  let!(:topic_2) { FactoryGirl.create :content_topic }

  resource_definitions = [
    {
      class_name: "Content::Models::Page",
      factory: :content_page,
      tag_relation: :page_topics,
    },
    {
      class_name: "Content::Models::Exercise",
      factory: :content_exercise,
      tag_relation: :exercise_topics,
    }
  ].collect{|rd| Hashie::Mash.new(rd)}

  resource_definitions.each do |resource_definition|
    it "assigns the given Topics to the given #{resource_definition.class_name}" do
      resource = FactoryGirl.create resource_definition.factory

      result = nil
      expect {
        result = Content::Routines::TagResourceWithTopics.call(resource, [topic_1, topic_2.name])
      }.to change{ resource.send(resource_definition.tag_relation).count }.by(2)
      expect(result.errors).to be_empty

      resource.reload
      expect(resource.send(resource_definition.tag_relation).collect{|t| t.topic}).to(
        eq [topic_1, topic_2])
    end
  end
end
