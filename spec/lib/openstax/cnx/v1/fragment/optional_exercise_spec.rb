require 'rails_helper'
require 'vcr_helper'

RSpec.describe OpenStax::Cnx::V1::Fragment::OptionalExercise, type: :external, vcr: VCR_OPTS do
  let(:reading_processing_instructions) {
    FactoryGirl.build(:content_book).reading_processing_instructions
  }
  let(:fragment_splitter)  {
    OpenStax::Cnx::V1::FragmentSplitter.new(reading_processing_instructions)
  }
  let(:cnx_page_id)        { '548a8717-71e1-4d65-80f0-7b8c6ed4b4c0@3' }
  let(:cnx_page)           { OpenStax::Cnx::V1::Page.new(id: cnx_page_id) }
  let(:fragments)          { fragment_splitter.split_into_fragments(cnx_page.converted_root) }
  let(:exercise_fragments) { fragments.select{ |f| f.instance_of? described_class } }

  let(:expected_tags)   {
    [ 'k12phys-ch04-ex038', 'k12phys-ch04-ex039' ]
  }

  it "provides info about the optional exercise fragment" do
    expect(exercise_fragments.size).to eq 1
    fragment = exercise_fragments.first
    expect(fragment.title).to be_nil
    expect(fragment.embed_tags).to eq expected_tags
  end
end
