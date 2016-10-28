FactoryGirl.define do
  factory :catalog_offering, class: '::Catalog::Models::Offering' do

    salesforce_book_name { "#{Faker::Lorem.word.capitalize} #{SecureRandom.uuid}" }
    appearance_code      { Faker::Lorem.word                                      }
    description          { Faker::Company.bs                                      }
    webview_url          { Faker::Internet.url                                    }
    pdf_url              { Faker::Internet.url                                    }
    default_course_name  { Faker::Lorem.words(2)                                  }
    is_concept_coach     false
    is_tutor             false
    is_available         true
    association :ecosystem, factory: :content_ecosystem

  end
end
