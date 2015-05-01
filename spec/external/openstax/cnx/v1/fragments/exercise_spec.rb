require 'rails_helper'
require 'vcr_helper'

RSpec.describe OpenStax::Cnx::V1::Fragments::Exercise, :type => :external,
                                                      :vcr => VCR_OPTS do
  let!(:cnx_page_id)    { '092bbf0d-0729-42ce-87a6-fd96fd87a083@4' }
  let!(:cnx_page)       { OpenStax::Cnx::V1::Page.new(id: cnx_page_id) }
  let!(:exercise_fragments) {
    cnx_page.fragments.select do |f|
      f.is_a? OpenStax::Cnx::V1::Fragments::Exercise
    end
  }
  let!(:expected_titles) { [ nil ] }
  let!(:expected_codes)  { [ "#ost/api/ex/k12phys-ch04-ex001" ] }
  let!(:expected_tags)   { [ 'k12phys-ch04-ex001' ] }

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
