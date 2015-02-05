require 'rails_helper'

RSpec.describe BelongsToResource do
  [:reading, :exercise, :interactive].each do |klass_name|
    subject(:r) { FactoryGirl.create klass_name }

    it { is_expected.to belong_to(:resource).dependent(:destroy) }

    it { is_expected.to validate_presence_of(:resource) }

    it { is_expected.to validate_uniqueness_of(:resource) }

    it "causes #{klass_name} to delegate methods to its resource" do
      expect(r.title).to eq r.resource.title
      expect(r.version).to eq r.resource.version
      expect(r.url).to eq r.resource.url
      expect(r.content).to eq r.resource.content
    end
  end
end
