require 'rails_helper'
require 'vcr_helper'

RSpec.describe OpenStax::Cnx::V1::Fragment::Exercise, type: :external, vcr: VCR_OPTS do
  let!(:cnx_page_id)        { '640e3e84-09a5-4033-b2a7-b7fe5ec29dc6@4' }
  let!(:cnx_page)           { OpenStax::Cnx::V1::Page.new(id: cnx_page_id) }
  let!(:exercise_fragments) {
    feature_fragments = cnx_page.fragments.select do |f|
      f.is_a? OpenStax::Cnx::V1::Fragment::Feature
    end
    feature_fragments.collect do |feature_fragment|
      feature_fragment.fragments.select do |f|
        f.is_a? OpenStax::Cnx::V1::Fragment::Exercise
      end
    end.flatten
  }
  let!(:expected_titles) { [ nil, nil ] }
  let!(:expected_codes)  {
    [ 'https://exercises-dev.openstax.org/api/exercises?q=tag%3Ak12phys-ch04-ex017',
      'https://exercises-dev.openstax.org/api/exercises?q=tag%3Ak12phys-ch04-ex073' ]
  }
  let!(:expected_tags)   { [ 'k12phys-ch04-ex017', 'k12phys-ch04-ex073' ] }

  it "provides info about the exercise fragment" do
    exercise_fragments.each do |fragment|
      expect(fragment.node).not_to be_nil
      expect(fragment.title).to be_nil
      expect(fragment.embed_code).not_to be_blank
      expect(fragment.embed_tag).not_to be_blank
    end
  end

  it "can retrieve the fragment's title" do
    expect(exercise_fragments.collect{|f| f.title}).to eq expected_titles
  end

  it "can retrieve the fragment's embed code" do
    expect(exercise_fragments.collect{|f| f.embed_code}).to eq expected_codes
  end

  it "can retrieve the fragment's  embed tag" do
    expect(exercise_fragments.collect{|f| f.embed_tag}).to eq expected_tags
  end
end
