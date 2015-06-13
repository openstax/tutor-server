FactoryGirl.define do
  factory :page do
    content_page
    initialize_with { new(content_page) }
    to_create {}
  end
end
