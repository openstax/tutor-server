FactoryGirl.define do
  factory :reading do
    resource nil

    after(:build) do |reading|
      reading.resource ||= FactoryGirl.build(:resource)
    end
  end
end
