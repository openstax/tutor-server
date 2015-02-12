require 'rails_helper'

RSpec.describe BelongsToResource do
  [:page, :exercise, :interactive].each do |klass_name|
    context klass_name do
      subject(:r) { FactoryGirl.create klass_name }

      it { is_expected.to belong_to(:resource).dependent(:destroy) }

      it { is_expected.to validate_presence_of(:resource) }

      it { is_expected.to validate_uniqueness_of(:resource) }

      it "causes #{klass_name} to delegate methods to its resource" do
        expect(r.url).to eq r.resource.url
        expect(r.content).to eq r.resource.content
        expect(r.topics).to eq r.resource.topics
      end
    end
  end

  context 'book' do
    subject(:book) { FactoryGirl.create :book }

    it { is_expected.to belong_to(:resource).dependent(:destroy) }

    it { is_expected.not_to validate_presence_of(:resource) }

    it { is_expected.to validate_uniqueness_of(:resource).allow_nil }

    it "causes book to delegate methods to its resource" do
      expect(book.url).to eq book.resource.url
      expect(book.content).to eq book.resource.content
      expect(book.topics).to eq book.resource.topics
    end
  end
end
