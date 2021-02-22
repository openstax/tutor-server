require 'rails_helper'
require 'vcr_helper'

RSpec.describe OpenStax::Cnx::V1::Fragment::OptionalExercise,
  type: :external, vcr: VCR_OPTS,
  skip: 'unable to locate any optional exercises in current books' do
  let(:reading_processing_instructions) do
    FactoryBot.build(:content_book).reading_processing_instructions
  end
  let(:reference_view_url) { Faker::Internet.url }
  let(:fragment_splitter)  do
    OpenStax::Cnx::V1::FragmentSplitter.new reading_processing_instructions, reference_view_url
  end
  let(:cnx_book) {
    OpenStax::Cnx::V1::Book.new(id: PopulateMiniEcosystem.cnx_book_hash[:id])
  }
  let(:cnx_page_id)        { 'b0ffd0a2-9c83-4d73-b899-7f2ade2acda6@3' }
  let(:cnx_page)           do
    OpenStax::Cnx::V1::Page.new(id: cnx_page_id, book: cnx_book).tap { |page| page.convert_content! }
  end
  let(:fragments)          { fragment_splitter.split_into_fragments(cnx_page.root) }
  let(:exercise_fragments) { fragments.select { |f| f.instance_of? described_class } }

  let(:expected_queries)   do
    []
  end

  it "provides info about the optional exercise fragment" do
    expect(exercise_fragments.any?).to be true
    fragment = exercise_fragments.first
    expect(fragment.title).to be_nil
    expect(fragment.embed_queries).to eq expected_queries
  end
end
