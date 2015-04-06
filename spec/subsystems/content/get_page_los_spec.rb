require 'rails_helper'

RSpec.describe Content::GetPageLos, :type => :routine do

  let!(:page_1) { FactoryGirl.create :content_page }
  let!(:page_2) { FactoryGirl.create :content_page }

  let!(:lo_1)   { FactoryGirl.create :content_tag, name: 'lo01', tag_type: :lo }
  let!(:lo_2)   { FactoryGirl.create :content_tag, name: 'lo02', tag_type: :lo }
  let!(:lo_3)   { FactoryGirl.create :content_tag, name: 'lo03', tag_type: :lo }

  let!(:page_1_lo_1) { FactoryGirl.create :content_page_tag, page: page_1,
                                                             tag: lo_1 }
  let!(:page_1_lo_2) { FactoryGirl.create :content_page_tag, page: page_1,
                                                             tag: lo_2 }
  let!(:page_2_lo_3) { FactoryGirl.create :content_page_tag, page: page_2,
                                                             tag: lo_3 }

  it "should get the LO's for a single page" do
    result = Content::GetPageLos.call(page_ids: page_1.id)
    expect(result.errors).to be_empty
    expect(result.outputs.los).to include(lo_1.name)
    expect(result.outputs.los).to include(lo_2.name)
    expect(result.outputs.los).not_to include(lo_3.name)

    result = Content::GetPageLos.call(page_ids: page_2.id)
    expect(result.errors).to be_empty
    expect(result.outputs.los).not_to include(lo_1.name)
    expect(result.outputs.los).not_to include(lo_2.name)
    expect(result.outputs.los).to include(lo_3.name)
  end

  it "should get the LO's for multiple pages" do
    result = Content::GetPageLos.call(page_ids: [page_1.id, page_2.id])
    expect(result.errors).to be_empty
    expect(result.outputs.los).to include(lo_1.name)
    expect(result.outputs.los).to include(lo_2.name)
    expect(result.outputs.los).to include(lo_3.name)
  end

end
