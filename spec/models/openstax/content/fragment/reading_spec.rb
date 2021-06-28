require 'rails_helper'
require 'vcr_helper'

RSpec.describe OpenStax::Content::Fragment::Reading, type: :external, vcr: VCR_OPTS do
  let(:reading_processing_instructions) do
    FactoryBot.build(:content_book).reading_processing_instructions
  end
  let(:reference_view_url) { Faker::Internet.url }
  let(:fragment_splitter)  do
    OpenStax::Content::FragmentSplitter.new reading_processing_instructions, reference_view_url
  end
  let(:page_uuid)          { MINI_ECOSYSTEM_OPENSTAX_PAGE_HASHES.first[:id] }
  let(:ox_page)            do
    OpenStax::Content::Page.new(book: MINI_ECOSYSTEM_OPENSTAX_BOOK, uuid: page_uuid)
  end
  let(:fragments)          { fragment_splitter.split_into_fragments(ox_page.root) }
  let(:reading_fragments)  { fragments.select { |f| f.instance_of? described_class } }

  it 'provides info about the reading fragment' do
    ox_page.convert_content!

    reading_fragments.each do |fragment|
      expect(fragment.title).to be_nil
      expect(fragment.to_html).not_to be_blank
    end
  end

  it 'changes links to objects not found in this fragment to point to the reference view' do
    ox_page.instance_variable_set :@content, <<~HTML
      <html>
        <body>
          <div id="content">
            <a href="#content">Content</a>

            <a href="#query">Query</a>
            <input name="query" type="text"/>

            <a href="#test">Test</a>

            <a href="#">Test random bad link</a>
          </div>
        </body>
      </html>
    HTML

    expect(reading_fragments.size).to eq 1
    reading_fragment = reading_fragments.first

    doc = Nokogiri::HTML.fragment(reading_fragment.to_html)
    body = doc.at_css('body')
    expect(body.at_css('[href="#"]')).not_to be_nil
    expect(body.at_css('[href="#content"]')).not_to be_nil
    expect(body.at_css('[href="#query"]')).not_to be_nil
    expect(body.at_css('[href="#test"]')).to be_nil
    expect(body.at_css("[href=\"#{reference_view_url}#test\"]")).not_to be_nil
  end
end
