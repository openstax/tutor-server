# coding: utf-8
require 'rails_helper'
require 'vcr_helper'

RSpec.describe OpenStax::Cnx::V1::Fragment::Video, type: :external, vcr: VCR_OPTS do
  let(:reading_processing_instructions) do
    FactoryBot.build(:content_book).reading_processing_instructions
  end
  let(:reference_view_url) { Faker::Internet.url }
  let(:fragment_splitter)  do
    OpenStax::Cnx::V1::FragmentSplitter.new reading_processing_instructions, reference_view_url
  end
  let(:cnx_page_id)        { PopulateMiniEcosystem.cnx_page_hashes.first[:id] }
  let(:cnx_page)           do
    OpenStax::Cnx::V1::Page.new(id: cnx_page_id).tap { |page| page.convert_content! }
  end
  let(:fragments)          { fragment_splitter.split_into_fragments(cnx_page.root) }
  let(:video_fragments)    { fragments.select { |f| f.instance_of? described_class } }

  let(:expected_title)     { "Watch Physics: Newton’s First Law of Motion" }
  let(:expected_url)       { 'https://www.khanacademy.org/embed_video?v=5-ZFOhHQS68' }
  let(:expected_content)   do
    <<~EOF
<div data-type="note" data-has-label="true" id="fs-id1169085651531" class="watch-physics" data-label="" data-tutor-transform="true">
<div data-type="title">Watch Physics: Newton’s First Law of Motion</div>



<div data-type="content">
<p id="fs-id1169085756824">This video introduces and explains Newton’s first law of motion.</p>
<div data-type="media" id="fs-id1169086146737" data-alt="This tutorial explains Newton’s first law of motion.">
<iframe width="660" height="371.4" src="https://www.openstaxcollege.org/l/02newlawone" class="os-embed video" title="Video"><!-- no-selfclose --></iframe>
</div>
</div>
</div>
    EOF
  end

  it 'provides info about the video fragment' do
    video_fragments.each do |fragment|
      expect(fragment.title).to eq expected_title
      content_lines = fragment.to_html.split("\n").map(&:strip)
      expected_content_lines = expected_content.split("\n").map(&:strip)
      expect(content_lines).to eq expected_content_lines
      expect(fragment.url).to eq expected_url
    end
  end
end
