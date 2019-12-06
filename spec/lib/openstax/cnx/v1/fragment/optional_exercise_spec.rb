require 'rails_helper'
require 'vcr_helper'

RSpec.describe OpenStax::Cnx::V1::Fragment::OptionalExercise, type: :external, vcr: VCR_OPTS do
  let(:reading_processing_instructions) do
    FactoryBot.build(:content_book).reading_processing_instructions
  end
  let(:reference_view_url) { Faker::Internet.url }
  let(:fragment_splitter)  do
    OpenStax::Cnx::V1::FragmentSplitter.new reading_processing_instructions, reference_view_url
  end
  let(:cnx_page_id)        { '548a8717-71e1-4d65-80f0-7b8c6ed4b4c0@3' }
  let(:cnx_page)           do
    OpenStax::Cnx::V1::Page.new(id: cnx_page_id).tap { |page| page.convert_content! }
  end
  let(:fragments)          { fragment_splitter.split_into_fragments(cnx_page.root) }
  let(:exercise_fragments) { fragments.select { |f| f.instance_of? described_class } }

  let(:expected_queries)   do
    [ [ :tag, 'k12phys-ch04-ex038' ], [ :tag, 'k12phys-ch04-ex039' ] ]
  end

  it "provides info about the optional exercise fragment" do
    expect(exercise_fragments.size).to eq 1
    fragment = exercise_fragments.first
    expect(fragment.title).to be_nil
    expect(fragment.embed_queries).to eq expected_queries
  end
end
