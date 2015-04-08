FactoryGirl.define do
  factory :content_exercise, class: '::Content::Models::Exercise' do
    content { OpenStax::Exercises::V1.fake_client.new_exercise_hash.to_json }

    transient do
      wrapper { OpenStax::Exercises::V1::Exercise.new(content) }
    end

    url { wrapper.url }
    title { wrapper.title }
  end
end
