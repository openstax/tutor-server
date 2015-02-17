FactoryGirl.define do
  factory :school do
    sequence(:name) { |n| "OSU #{School.count+1}" }
    default_time_zone { ActiveSupport::TimeZone.us_zones.map(&:to_s).first }

    transient do
      courses_count 0
      school_managers_count 0
    end

    after(:build) do |school, evaluator|
      evaluator.courses_count.times do 
        school.courses << FactoryGirl.build(:course)
      end
      evaluator.school_managers_count.times do 
        school.school_managers << FactoryGirl.build(:school_manager)
      end
    end
  end

end
