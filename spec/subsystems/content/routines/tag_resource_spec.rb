require 'rails_helper'

RSpec.describe Content::Routines::TagResource, type: :routine do
  let(:tag_1)    { 'testing' }
  let(:tag_2)    { 'tags' }
  let(:lo_tag_1) { 'lo:stax-test:1-1-1' }
  let(:lo_tag_2) { 'lo:stax-test:1-2-1' }

  resource_definitions = [
    {
      class_name: "Content::Models::Page",
      factory: :content_page,
      tagging_relation: :page_tags,
    },
    {
      class_name: "Content::Models::Exercise",
      factory: :content_exercise,
      tagging_relation: :exercise_tags,
    }
  ].map { |rd| Hashie::Mash.new(rd) }

  resource_definitions.each do |resource_definition|
    it "assigns the given Tags to the given #{resource_definition.class_name}" do
      resource = FactoryBot.create resource_definition.factory

      result = nil
      expect do
        result = Content::Routines::TagResource.call(
          ecosystem: resource.ecosystem, resource: resource, tags: [tag_1, tag_2]
        )
      end.to change { resource.send(resource_definition.tagging_relation).count }.by(2)

      expect(result.errors).to be_empty

      resource.reload

      expected_values = [tag_1, tag_2]
      actual_tags = resource.send(resource_definition.tagging_relation).map(&:tag)
      actual_values = actual_tags.map(&:value)
      expect(Set.new actual_values).to eq Set.new expected_values

      expected_tag_types = ['generic', 'generic']
      actual_tag_types = actual_tags.map(&:tag_type)
      expect(Set.new actual_tag_types).to eq Set.new expected_tag_types

      expect do
        result = Content::Routines::TagResource.call(
          ecosystem: resource.ecosystem, resource: resource, tags: [lo_tag_1, lo_tag_2]
        )
      end.to change { resource.send(resource_definition.tagging_relation).count }.by(2)

      expect(result.errors).to be_empty

      resource.reload

      expected_values = [tag_1, tag_2, lo_tag_1, lo_tag_2]
      actual_tags = resource.send(resource_definition.tagging_relation).map(&:tag)
      actual_values = actual_tags.map(&:value)
      expect(Set.new actual_values).to eq Set.new expected_values

      expected_tag_types = ['generic', 'generic', 'lo', 'lo']
      actual_tag_types = actual_tags.map(&:tag_type)
      expect(Set.new actual_tag_types).to eq Set.new expected_tag_types
    end
  end
end
