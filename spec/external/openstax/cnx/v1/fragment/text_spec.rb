require 'rails_helper'
require 'vcr_helper'

RSpec.describe OpenStax::Cnx::V1::Fragment::Text, :type => :external,
                                                  :vcr => VCR_OPTS do
  let!(:cnx_page_id)    { '092bbf0d-0729-42ce-87a6-fd96fd87a083@4' }
  let!(:cnx_page)       { OpenStax::Cnx::V1::Page.new(id: cnx_page_id) }
  let!(:text_fragments) {
    cnx_page.fragments.select { |f| f.is_a? OpenStax::Cnx::V1::Fragment::Text }
  }
  let!(:expected_titles) {
    [ "Section Learning Objectives; Defining Force and Dynamics",
      "Mars Probe Explosion",
      "Free-body Diagrams and Examples of Forces" ]
  }

  it "provides info about the text fragment" do
    text_fragments.each do |fragment|
      expect(fragment.node).not_to be_nil
      expect(fragment.title).not_to be_blank
      expect(fragment.to_html).not_to be_blank
    end
  end

  it "can retrieve the fragment's title" do
    expect(text_fragments.collect{|f| f.title}).to eq expected_titles
  end
end
