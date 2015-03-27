FactoryGirl.define do
  sequence :tag_name do |n| "Tag #{n}" end

  factory :content_tag, class: '::Content::Models::Tag' do
    name { generate(:tag_name) }
  end
end
