require 'rails_helper'

RSpec.describe Content::TagResource, :type => :routine do
  let!(:tag_1) { FactoryGirl.create :content_tag }
  let!(:tag_2) { FactoryGirl.create :content_tag }

  resource_definitions = [
    {
      class_name: "Content::Page",
      factory: :content_page,
      tag_relation: :page_tags,
    },
    {
      class_name: "Content::Exercise",
      factory: :content_exercise,
      tag_relation: :exercise_tags,
    }
  ].collect{|rd| Hashie::Mash.new(rd)}

  resource_definitions.each do |resource_definition|
    it "assigns the given Tags to the given #{resource_definition.class_name}" do
      resource = FactoryGirl.create resource_definition.factory

      result = nil
      expect {
        result = Content::TagResource.call(
          resource, [tag_1, tag_2.name], tag_type: :lo
        )
      }.to change{ resource.send(resource_definition.tag_relation).count }.by(2)
      expect(result.errors).to be_empty

      resource.reload
      expect(resource.send(resource_definition.tag_relation)
                     .collect{|t| t.tag}).to eq [tag_1, tag_2]
      expect(resource.send(resource_definition.tag_relation)
                     .collect{|t| t.tag.tag_type}).to eq [:lo, :lo]
    end
  end
end
