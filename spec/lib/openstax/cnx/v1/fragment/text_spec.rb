require 'rails_helper'
require 'vcr_helper'

RSpec.describe OpenStax::Cnx::V1::Fragment::Text, type: :external, vcr: VCR_OPTS do
  let!(:cnx_page_id)    { '95e61258-2faf-41d4-af92-f62e1414175a@4' }
  let!(:cnx_page)       { OpenStax::Cnx::V1::Page.new(id: cnx_page_id) }
  let!(:text_fragments) {
    cnx_page.fragments.select { |f| f.is_a? OpenStax::Cnx::V1::Fragment::Text }
  }
  let!(:expected_titles) {
    [ "Section Learning Objectives; Defining Force and Dynamics; Free-body Diagrams and Examples of Forces" ]
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
