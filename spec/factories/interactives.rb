FactoryGirl.define do
  factory :interactive do
    resource nil

    after(:build) do |interactive|
      interactive.resource ||= FactoryGirl.build(:resource)
    end
  end
end
