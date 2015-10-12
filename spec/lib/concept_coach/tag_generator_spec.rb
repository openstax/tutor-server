require 'rails_helper'

module ConceptCoach
  RSpec.describe TagGenerator, type: :lib do
    let(:book_name)     { 'econ' }
    let(:book_location) { [2, 3] }
    let(:valid_tags)    { [ { value: 'econ-ch02-s03', type: :cc } ] }

    it 'stores a string and uses it to generate tags later based on book_location' do
      tag_generator = TagGenerator.new book_name
      expect(tag_generator.generate(book_location)).to eq valid_tags
    end

    it 'produces no tags if the original string is blank' do
      tag_generator = TagGenerator.new ''
      expect(tag_generator.generate(book_location)).to eq []
    end
  end
end
