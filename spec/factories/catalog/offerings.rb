FactoryBot.define do
  factory :catalog_offering, class: '::Catalog::Models::Offering' do
    ecosystem            { build(:content_book).ecosystem }

    salesforce_book_name { "#{Faker::Lorem.word.capitalize} #{SecureRandom.uuid}" }
    appearance_code      { Faker::Lorem.word                                      }
    title                { Faker::Lorem.words(2).join(' ').capitalize             }
    description          { Faker::Company.bs                                      }
    webview_url          { Faker::Internet.url                                    }
    pdf_url              { Faker::Internet.url                                    }
    default_course_name  { Faker::Lorem.words(2).join(' ').capitalize             }
    is_concept_coach     { false }
    is_tutor             { true }
    is_preview_available { true }
    is_available         { true }
  end
end
