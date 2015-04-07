require 'rails_helper'

RSpec.describe Content::GetLos, :type => :routine do

  let!(:book_part_1) { FactoryGirl.create :content_book_part }
  let!(:book_part_2) { FactoryGirl.create :content_book_part }

  let!(:page_1) { FactoryGirl.create :content_page, book_part: book_part_1 }
  let!(:page_2) { FactoryGirl.create :content_page, book_part: book_part_1 }
  let!(:page_3) { FactoryGirl.create :content_page, book_part: book_part_2 }

  let!(:lo_1)   { FactoryGirl.create :content_tag, name: 'lo01', tag_type: :lo }
  let!(:lo_2)   { FactoryGirl.create :content_tag, name: 'lo02', tag_type: :lo }
  let!(:lo_3)   { FactoryGirl.create :content_tag, name: 'lo03', tag_type: :lo }
  let!(:lo_4)   { FactoryGirl.create :content_tag, name: 'lo04', tag_type: :lo }
  let!(:lo_5)   { FactoryGirl.create :content_tag, name: 'lo05', tag_type: :lo }

  let!(:page_1_lo_1) { FactoryGirl.create :content_page_tag, page: page_1,
                                                             tag: lo_1 }
  let!(:page_1_lo_2) { FactoryGirl.create :content_page_tag, page: page_1,
                                                             tag: lo_2 }
  let!(:page_2_lo_3) { FactoryGirl.create :content_page_tag, page: page_2,
                                                             tag: lo_3 }
  let!(:page_3_lo_4) { FactoryGirl.create :content_page_tag, page: page_3,
                                                             tag: lo_4 }
  let!(:page_3_lo_5) { FactoryGirl.create :content_page_tag, page: page_3,
                                                             tag: lo_5 }

  it "should get the LO's for a single page" do
    result = Content::GetLos.call(page_ids: page_1.id)
    expect(result.errors).to be_empty
    expect(result.outputs.los).to include(lo_1.name)
    expect(result.outputs.los).to include(lo_2.name)
    expect(result.outputs.los).not_to include(lo_3.name)
    expect(result.outputs.los).not_to include(lo_4.name)
    expect(result.outputs.los).not_to include(lo_5.name)

    result = Content::GetLos.call(page_ids: page_2.id)
    expect(result.errors).to be_empty
    expect(result.outputs.los).not_to include(lo_1.name)
    expect(result.outputs.los).not_to include(lo_2.name)
    expect(result.outputs.los).to include(lo_3.name)
    expect(result.outputs.los).not_to include(lo_4.name)
    expect(result.outputs.los).not_to include(lo_5.name)
  end

  it "should get the LO's for multiple pages" do
    result = Content::GetLos.call(page_ids: [page_1.id, page_2.id])
    expect(result.errors).to be_empty
    expect(result.outputs.los).to include(lo_1.name)
    expect(result.outputs.los).to include(lo_2.name)
    expect(result.outputs.los).to include(lo_3.name)
    expect(result.outputs.los).not_to include(lo_4.name)
    expect(result.outputs.los).not_to include(lo_5.name)
  end

  it "should get the LO's for a single book_part" do
    result = Content::GetLos.call(book_part_ids: book_part_1.id)
    expect(result.errors).to be_empty
    expect(result.outputs.los).to include(lo_1.name)
    expect(result.outputs.los).to include(lo_2.name)
    expect(result.outputs.los).to include(lo_3.name)
    expect(result.outputs.los).not_to include(lo_4.name)
    expect(result.outputs.los).not_to include(lo_5.name)

    result = Content::GetLos.call(book_part_ids: book_part_2.id)
    expect(result.errors).to be_empty
    expect(result.outputs.los).not_to include(lo_1.name)
    expect(result.outputs.los).not_to include(lo_2.name)
    expect(result.outputs.los).not_to include(lo_3.name)
    expect(result.outputs.los).to include(lo_4.name)
    expect(result.outputs.los).to include(lo_5.name)
  end

  it "should get the LO's for multiple book_parts" do
    result = Content::GetLos.call(book_part_ids: [book_part_1.id,
                                                  book_part_2.id])
    expect(result.errors).to be_empty
    expect(result.outputs.los).to include(lo_1.name)
    expect(result.outputs.los).to include(lo_2.name)
    expect(result.outputs.los).to include(lo_3.name)
    expect(result.outputs.los).to include(lo_4.name)
    expect(result.outputs.los).to include(lo_5.name)
  end

  it "should get the LO's for pages mixed with book parts" do
    result = Content::GetLos.call(page_ids: page_2.id,
                                  book_part_ids: book_part_2.id)
    expect(result.errors).to be_empty
    expect(result.outputs.los).not_to include(lo_1.name)
    expect(result.outputs.los).not_to include(lo_2.name)
    expect(result.outputs.los).to include(lo_3.name)
    expect(result.outputs.los).to include(lo_4.name)
    expect(result.outputs.los).to include(lo_5.name)
  end

end
