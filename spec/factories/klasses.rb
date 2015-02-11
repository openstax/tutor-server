FactoryGirl.define do
  factory :klass do
    transient do 
      starting_time Time.now
      start_to_end 3.months
      visible_to_start 7.days
      end_to_invisible 7.days
    end

    course
    starts_at { starting_time }
    ends_at { starting_time + start_to_end }
    visible_at { starting_time - visible_to_start }
    invisible_at { ends_at + end_to_invisible }
    time_zone { ActiveSupport::TimeZone.us_zones.map(&:to_s).first }
    approved_emails ""
    allow_student_custom_identifier false
  end
end
