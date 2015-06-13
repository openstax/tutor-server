require 'rails_helper'

RSpec.describe Page, type: :model do
  subject(:page)     { FactoryGirl.create :page }
  let!(:lo)          { FactoryGirl.create :content_tag, tag_type: :lo }
  let!(:tag)         { FactoryGirl.create :content_tag }
  let!(:tagging_1)   { FactoryGirl.create :content_page_tag, tag: lo, page: page._repository }
  let!(:tagging_2)   { FactoryGirl.create :content_page_tag, tag: tag, page: page._repository }

  it 'exposes url, title, content, chapter_section, book_part, is_intro?, fragments, tags and los' do
    [:url, :title, :content, :chapter_section, :book_part, :is_intro?, :fragments, :tags, :los].each do |method_name|
      expect(page).to respond_to(method_name)
    end

    expect(page.url).not_to be_blank
    expect(JSON.parse(page.content)).not_to be_blank
    expect(page.chapter_section).not_to be_blank
    expect(page.book_part).not_to be_blank
    expect(page.is_intro?).to eq false
    expect(page.fragments).not_to be_blank
    expect(page.tags).to include(tag.value)
    expect(page.tags).to include(lo.value)
    expect(page.los).not_to include(tag.value)
    expect(page.los).to include(lo.value)
  end
end
