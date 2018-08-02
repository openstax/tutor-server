require 'rails_helper'
require 'vcr_helper'

RSpec.describe OpenStax::Cnx::V1::Fragment::Exercise, type: :external, vcr: VCR_OPTS do
  let(:reading_processing_instructions) do
    FactoryBot.build(:content_book).reading_processing_instructions
  end
  let(:fragment_splitter)  do
    OpenStax::Cnx::V1::FragmentSplitter.new(reading_processing_instructions)
  end
  let(:cnx_page_id)        { '640e3e84-09a5-4033-b2a7-b7fe5ec29dc6@4' }
  let(:cnx_page)           { OpenStax::Cnx::V1::Page.new(id: cnx_page_id) }
  let(:fragments)          { fragment_splitter.split_into_fragments(cnx_page.converted_root) }
  let(:exercise_fragments) { fragments.select { |f| f.instance_of? described_class } }

  let(:expected_queries)   do
    [ [ [ :tag, 'k12phys-ch04-ex017'] ], [ [ :nickname, 'Some Exercise'] ] ]
  end

  it 'provides info about the exercise fragment' do
    exercise_fragments.each_with_index do |fragment, index|
      expect(fragment.title).to be_nil
      expect(fragment.embed_queries).to eq expected_queries[index]
    end
  end

  it 'can absolutize exercise tag urls' do
    absolutized_node = OpenStax::Cnx::V1::Fragment::Exercise.absolutize_exercise_urls(
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
    absolutized_node = OpenStax::Cnx::V1::Fragment::Exercise.absolutize_exercise_urls(
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
