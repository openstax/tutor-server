FactoryGirl.define do
  factory :content_exercise, class: '::Content::Models::Exercise' do
    association :page, factory: :content_page

    sequence(:number) { |n| -n }
    version           1
    url               { wrapper.url }
    title             { wrapper.title }

    transient do
      uid       nil
      tags      nil
      num_parts 1
      wrapper   { OpenStax::Exercises::V1::Exercise.new(content: content) }
    end

    content   do
      OpenStax::Exercises::V1::FakeClient.new_exercise_hash(
        number: number, version: version, uid: uid, tags: tags, num_parts: num_parts
      ).to_json
    end
  end
end
