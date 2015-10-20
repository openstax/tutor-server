require 'rails_helper'
require 'vcr_helper'

RSpec.describe OpenStax::Cnx::V1::Fragment::Video, type: :external, vcr: VCR_OPTS do
  let!(:cnx_page_id) { '640e3e84-09a5-4033-b2a7-b7fe5ec29dc6@4' }
  let!(:cnx_page)       { OpenStax::Cnx::V1::Page.new(id: cnx_page_id) }
  let!(:video_fragments) {
    feature_fragments = cnx_page.fragments.select do |f|
      f.is_a? OpenStax::Cnx::V1::Fragment::Feature
    end
    feature_fragments.collect do |feature_fragment|
      feature_fragment.fragments.select do |f|
        f.is_a? OpenStax::Cnx::V1::Fragment::Video
      end
    end.flatten
  }
  let!(:expected_titles) { ['Newton’s First Law of Motion'] }
  let!(:expected_urls) { ['https://www.khanacademy.org/embed_video?v=5-ZFOhHQS68'] }
  let!(:expected_content) { [
<<EOF.rstrip
<div data-type="note" data-has-label="true" id="fs-idp2684240" class="note watch-physics ost-assessed-feature ost-video ost-tag-lo-k12phys-ch04-s02-lo01" data-label="Watch Physics">
<div data-type="title" class="title">Newton’s First Law of Motion</div>

<p id="fs-idp29827984">This video contrasts the way we thought about motion and force in the time before Galileo’s concept of inertia and Newton’s first law of motion with the way we understand force and motion now.</p>
 <iframe width="660" height="371.4" src="https://www.khanacademy.org/embed_video?v=5-ZFOhHQS68"></iframe>

</div>
EOF
  ] }

  it 'provides info about the video fragment' do
    video_fragments.each do |fragment|
      expect(fragment.node).not_to be_nil
      expect(fragment.title).not_to be_nil
      expect(fragment.to_html).not_to be_nil
      expect(fragment.url).not_to be_nil
    end
  end

  it "can retrieve the fragment's title" do
    expect(video_fragments.collect { |f| f.title }).to eq expected_titles
  end

  it "can retrieve the fragment's video url" do
    expect(video_fragments.collect { |f| f.url }).to eq expected_urls
  end

  it "can retrieve the fragment's content" do
    # The content should remove the link tag but keep the tag content
    expect(video_fragments.collect { |f| f.to_html }).to eq expected_content
  end
end
