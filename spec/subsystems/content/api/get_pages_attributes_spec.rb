require 'rails_helper'

RSpec.describe Content::Api::GetPagesAttributes, :type => :routine do

  let(:row_count) { 3 }
  let(:pages){ row_count.times.map{ FactoryGirl.create(:content_page) } }
  let(:page_ids){ pages.map(&:id) }

  it "returns rows matching each record" do
    results = Content::Api::GetPagesAttributes.call(page_ids:page_ids).outputs.pages
    0.upto(row_count-1) do |row|
      Content::Api::GetPagesAttributes::EXPORTED_COLUMNS.each do | key |
        expect(results[row][key]).to eq( pages[row].read_attribute(key) )
      end
    end
  end


end
