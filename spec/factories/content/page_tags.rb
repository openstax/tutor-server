FactoryGirl.define do
  factory :content_page_tag, class: '::Content::PageTag' do
    association :page, factory: :content_page
    association :tag, factory: :content_tag
  end
end
