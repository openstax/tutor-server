FactoryBot.define do
  factory :payment_code, class: 'PaymentCode' do
    prefix { 'ABC' }
    association :student, factory: :course_membership_student
  end
end
