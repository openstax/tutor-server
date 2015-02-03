FactoryGirl.define do
  factory :exercise do
    resource nil

    after(:build) do |exercise|
      exercise.resource ||= FactoryGirl.build(:resource)
    end
  end
end
