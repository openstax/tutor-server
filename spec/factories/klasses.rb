# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :klass do
    course_id 1
    starts_at "2014-09-23 12:58:26"
    ends_at "2014-09-23 12:58:26"
    visible_at "2014-09-23 12:58:26"
    invisible_at "2014-09-23 12:58:26"
    time_zone "MyString"
    approved_emails "MyText"
    allow_student_custom_identifier false
  end
end
