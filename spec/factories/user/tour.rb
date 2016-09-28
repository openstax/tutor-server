FactoryGirl.define do
  factory :user_tour, class: 'User::Models::Tour' do
    identifier { Faker::Lorem.word }
  end
end
