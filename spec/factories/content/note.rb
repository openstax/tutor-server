FactoryBot.define do
  factory :content_note, class: '::Content::Models::Note' do

    association :page, factory: :content_page
    association :role, factory: :entity_role

    anchor { SecureRandom.hex(4) }

    contents { { one: 1 } }
  end
end
