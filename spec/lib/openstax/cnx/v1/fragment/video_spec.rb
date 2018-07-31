# coding: utf-8
require 'rails_helper'
require 'vcr_helper'

RSpec.describe OpenStax::Cnx::V1::Fragment::Video, type: :external, vcr: VCR_OPTS do
  let(:reading_processing_instructions) {
    FactoryBot.build(:content_book).reading_processing_instructions
  }
  let(:fragment_splitter) {
    OpenStax::Cnx::V1::FragmentSplitter.new(reading_processing_instructions)
  }
  let(:cnx_page_id)       { '640e3e84-09a5-4033-b2a7-b7fe5ec29dc6@4' }
  let(:cnx_page)          { OpenStax::Cnx::V1::Page.new(id: cnx_page_id) }
  let(:fragments)         { fragment_splitter.split_into_fragments(cnx_page.converted_root) }
  let(:video_fragments)   { fragments.select{ |f| f.instance_of? described_class } }

  let(:expected_title)   { 'Newton’s First Law of Motion' }
  let(:expected_url)     { 'https://www.khanacademy.org/embed_video?v=5-ZFOhHQS68' }
  let(:expected_content) {
    <<-EOF.strip_heredoc.rstrip
      <div data-type="note" data-has-label="true" id="fs-idp2684240" class="note watch-physics ost-assessed-feature ost-video ost-tag-lo-k12phys-ch04-s02-lo01" data-label="Watch Physics" data-tutor-transform="true">
      <div data-type="title" class="title">Newton’s First Law of Motion</div>


       


      <div data-type="content">
      <p id="fs-idp29827984">This video contrasts the way we thought about motion and force in the time before Galileo’s concept of inertia and Newton’s first law of motion with the way we understand force and motion now.</p>
      <div data-type="media" id="fs-idp48266880" data-alt="This link takes you to a lecture that contrasts the way we thought about motion and force before Galileo's concept of inertia and Newton's first law of motion with the way we understand force and motion now." class="os-embed">
        <iframe width="660" height="371.4" src="https://www.khanacademy.org/embed_video?v=5-ZFOhHQS68" class="os-embed video" title="Video"></iframe>
      </div>
      </div>
      </div>
    EOF
  }

  it 'provides info about the video fragment' do
    video_fragments.each do |fragment|
      expect(fragment.title).to eq expected_title
      expect(fragment.to_html).to eq expected_content
      expect(fragment.url).to eq expected_url
    end
  end
end
