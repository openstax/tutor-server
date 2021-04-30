require 'rails_helper'
require 'vcr_helper'

RSpec.describe OpenStax::Cnx::V1::Fragment::Exercise, type: :external, vcr: VCR_OPTS do
  let(:reading_processing_instructions) do
    FactoryBot.build(:content_book).reading_processing_instructions
  end
  let(:reference_view_url) { Faker::Internet.url }
  let(:fragment_splitter)  do
    OpenStax::Cnx::V1::FragmentSplitter.new reading_processing_instructions, reference_view_url
  end
  let(:cnx_page_id)        { MINI_ECOSYSTEM_CNX_PAGE_HASHES.first[:id] }
  let(:cnx_page)           do
    OpenStax::Cnx::V1::Page.new(id: cnx_page_id).tap { |page| page.convert_content! }
  end
  let(:fragments)          { fragment_splitter.split_into_fragments(cnx_page.root) }
  let(:exercise_fragments) { fragments.select { |f| f.instance_of? described_class } }

  let(:expected_queries)   do
    [[]]
  end

  it 'provides info about the exercise fragment' do
    exercise_fragments.each_with_index do |fragment, index|
      expect(fragment.title).to be_nil
      expect(fragment.embed_queries).to eq expected_queries[index]
    end
  end

  it 'can absolutize exercise tag urls' do
    absolutized_node = OpenStax::Cnx::V1::Fragment::Exercise.absolutize_exercise_urls!(
      Nokogiri::HTML.fragment(
        "<div class=\"exercise\">
           <a href=\"#ost/api/ex/some-tag\">[Link]</a>
         </div>"
      )
    ).at_css('a')
    expected_url = OpenStax::Exercises::V1.uri_for('/api/exercises').tap do |uri|
      uri.query_values = { q: 'tag:"some-tag"' }
    end.to_s

    expect(absolutized_node['href']).to eq expected_url
    expect(absolutized_node['data-type']).to eq 'exercise'
  end

  it 'can absolutize exercise nickname urls' do
    absolutized_node = OpenStax::Cnx::V1::Fragment::Exercise.absolutize_exercise_urls!(
      Nokogiri::HTML.fragment(
        "<div class=\"exercise\">
           <a href=\"#exercise/Some Nickname\">[Link]</a>
         </div>"
      )
    ).at_css('a')
    expected_url = OpenStax::Exercises::V1.uri_for('/api/exercises').tap do |uri|
      uri.query_values = { q: 'nickname:"Some Nickname"' }
    end.to_s

    expect(absolutized_node['href']).to eq expected_url
    expect(absolutized_node['data-type']).to eq 'exercise'
  end
end
