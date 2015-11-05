FactoryGirl.define do
  factory :catalog_offering, class: '::Catalog::Models::Offering' do

    identifier  { Faker::Lorem.word   }
    description { Faker::Company.bs   }
    webview_url { Faker::Internet.url }
    pdf_url     { Faker::Internet.url }
    association :ecosystem, factory: :content_ecosystem

  end
end
