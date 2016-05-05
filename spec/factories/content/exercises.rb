FactoryGirl.define do
  factory :content_exercise, class: '::Content::Models::Exercise' do
    transient do
      num_parts 1
    end

    content   { OpenStax::Exercises::V1.fake_client.new_exercise_hash(num_parts: num_parts)
                                                   .to_json }

    transient do
      wrapper { OpenStax::Exercises::V1::Exercise.new(content: content) }
      uid     { wrapper.uid }
    end

    association :page, factory: :content_page

    number    { wrapper.uid.split('@').first }
    version   { wrapper.uid.split('@').last }
    url       { wrapper.url }
    title     { wrapper.title }
  end
end
