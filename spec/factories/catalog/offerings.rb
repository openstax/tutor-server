FactoryGirl.define do
  factory :catalog_offering, class: '::Catalog::Models::Offering' do

    identifier  { Faker::Lorem.word   }
    webview_url { Faker::Internet.url }
    description { Faker::Company.bs   }

  end
end
