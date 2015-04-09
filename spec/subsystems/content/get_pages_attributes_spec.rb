require 'rails_helper'

RSpec.describe Content::GetPagesAttributes, :type => :routine do

  let(:row_count) { 3 }
  let(:pages){ row_count.times.map{ FactoryGirl.create(:content_page) } }
  let(:page_ids){ pages.map(&:id) }

  it "returns rows matching each record" do
    results = Content::GetPagesAttributes.call(page_ids:page_ids).outputs.pages
    found_ids = Set.new results.map{|rec| rec.id}
    expect(found_ids).to eq(Set.new(page_ids))
  end


end
