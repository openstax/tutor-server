FactoryBot.define do
  factory :user_suggestion, class: 'User::Models::Suggestion' do
    content { Faker::Lorem.word }
    topic { 0 }
  end
end
