require 'rails_helper'
require 'vcr_helper'

RSpec.describe OpenStax::Cnx::V1::Fragment::Video, :type => :external,
                                             :vcr => VCR_OPTS do
  let!(:cnx_page_id) { '61445f78-00e2-45ae-8e2c-461b17d9b4fd' }
  let!(:cnx_page) { OpenStax::Cnx::V1::Page.new(id: cnx_page_id) }
  let!(:video_fragments) {
    cnx_page.fragments.select do |f|
      f.is_a? OpenStax::Cnx::V1::Fragment::Video
    end
  }
  let!(:expected_titles) { ['Newton’s first law of motion'] }
  let!(:expected_urls) { ['https://www.khanacademy.org/science/physics/forces-newtons-laws/newtons-laws-of-motion/v/newton-s-1st-law-of-motion'] }

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
end
