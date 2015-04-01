require 'rails_helper'

RSpec.describe Content::Routines::TagResource, :type => :routine do
  let!(:tag_1)     { FactoryGirl.create :content_tag }
  let!(:tag_2)     { FactoryGirl.create :content_tag }
  let!(:new_tag_1) { FactoryGirl.build  :content_tag }
  let!(:new_tag_2) { FactoryGirl.build  :content_tag }

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
  ].collect{|rd| Hashie::Mash.new(rd)}

  resource_definitions.each do |resource_definition|
    it "assigns the given Tags to the given #{resource_definition.class_name}" do
      resource = FactoryGirl.create resource_definition.factory

      result = nil
      expect {
        result = Content::Routines::TagResource.call(
          resource, [tag_1, tag_2.name]
        )
      }.to change{
        resource.send(resource_definition.tagging_relation).count
      }.by(2)

      expect(result.errors).to be_empty

      resource.reload

      expected_tags = [tag_1, tag_2]
      actual_tags = resource.send(resource_definition.tagging_relation)
                            .collect{|tagging| tagging.tag}

      expected_tag_names = expected_tags.collect{|t| t.name}
      actual_tag_names = actual_tags.collect{|t| t.name}
      expect(Set.new actual_tag_names).to eq Set.new expected_tag_names

      expected_tag_types = ['generic', 'generic']
      actual_tag_types = actual_tags.collect{|t| t.tag_type}
      expect(Set.new actual_tag_types).to eq Set.new expected_tag_types

      expect {
        result = Content::Routines::TagResource.call(
          resource, [new_tag_1, new_tag_2.name], tag_type: :lo
        )
      }.to change{
        resource.send(resource_definition.tagging_relation).count
      }.by(2)

      expect(result.errors).to be_empty

      resource.reload

      expected_tags = [tag_1, tag_2, new_tag_1, new_tag_2]
      actual_tags = resource.send(resource_definition.tagging_relation)
                            .collect{|tagging| tagging.tag}

      expected_tag_names = expected_tags.collect{|t| t.name}
      actual_tag_names = actual_tags.collect{|t| t.name}
      expect(Set.new actual_tag_names).to eq Set.new expected_tag_names

      expected_tag_types = ['generic', 'generic', 'lo', 'lo']
      actual_tag_types = actual_tags.collect{|t| t.tag_type}
      expect(Set.new actual_tag_types).to eq Set.new expected_tag_types
    end
  end
end
