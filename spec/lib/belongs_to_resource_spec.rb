require 'rails_helper'

RSpec.describe BelongsToResource do
  [:reading, :exercise, :interactive].each do |resource_class|
    subject(:rclass) { FactoryGirl.create resource_class }

    it { is_expected.to belong_to(:resource).dependent(:destroy) }

    it "causes #{resource_class} to delegate methods to its resource" do
      expect(rclass.url).to eq rclass.resource.url
      expect(rclass.content).to eq rclass.resource.content
    end
  end
end
