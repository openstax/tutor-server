require 'rails_helper'
require 'vcr_helper'

RSpec.describe OpenStax::Cnx::V1::Fragment::Interactive, type: :external, vcr: VCR_OPTS do
  let!(:cnx_page_id) { '61445f78-00e2-45ae-8e2c-461b17d9b4fd@4' }
  let!(:cnx_page)       {
    OpenStax::Cnx::V1.with_archive_url(url: 'https://archive.cnx.org/contents/') do
      OpenStax::Cnx::V1::Page.new(id: cnx_page_id)
    end
  }
  let!(:interactive_fragments) {
    cnx_page.fragments.select do |f|
      f.is_a? OpenStax::Cnx::V1::Fragment::Interactive
    end
  }
  let!(:expected_titles) { ['Forces and Motion: Basics'] }
  let!(:expected_urls) { ['https://archive.cnx.org/specials/e2ca52af-8c6b-450e-ac2f-9300b38e8739/moving-man/'] }
  let!(:expected_content) { [<<EOF.rstrip
<div data-type="note" id="fs-idm38320288" class="ost-assessed-feature ost-interactive virtual-physics ost-tag-lo-k12phys-ch04-s02-lo02" data-label="Virtual Physics">
<div data-type="title">Forces and Motion: Basics</div>

<p id="fs-idp34383024">In this simulation, you will first explore net force by placing blue people on the left side of a tug of war rope and red people on the right side of the rope (by clicking people and dragging them with your mouse). Experiment with changing the number and size of people on each side to see how it affects the outcome of the match and the net force. Hit the Go! button to start the match, and the “reset all” button to start over.</p>
<ol id="fs-idp48496992" data-number-style="lower-alpha">
<li>The side with the most force wins</li>
<li>The bigger the difference in the force, the easier it is for one side to win.</li>
<li>When force is equal, no one wins.</li>
</ol>
<p id="fs-idp52126304">Next, click on the Friction tab. Try selecting different objects for the person to push. Slide the applied force button to the right to apply force to the right and to the left to apply force to the left. The force will continue to be applied as long as you hold the button down. See the arrow representing friction change in magnitude and direction depending on how much force you apply. Try increasing or decreasing the friction force to see how this affects the motion.</p>
<iframe width="960" height="785" src="https://archive.cnx.org/specials/e2ca52af-8c6b-450e-ac2f-9300b38e8739/moving-man/"></iframe>\n\n  </div>
EOF
  ] }

  it 'provides info about the interactive fragment' do
    interactive_fragments.each do |fragment|
      expect(fragment.node).not_to be_nil
      expect(fragment.title).not_to be_nil
      expect(fragment.to_html).not_to be_nil
      expect(fragment.url).not_to be_nil
    end
  end

  it "can retrieve the fragment's title" do
    expect(interactive_fragments.collect { |f| f.title }).to eq(expected_titles)
  end

  it "can retrieve the fragment's interactive url" do
    expect(interactive_fragments.collect { |f| f.url }).to eq(expected_urls)
  end

  it "can retrieve the fragment's content" do
    expect(interactive_fragments.collect { |f| f.to_html }).to eq(expected_content)
  end
end
