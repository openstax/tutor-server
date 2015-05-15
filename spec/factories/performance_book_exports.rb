FactoryGirl.define do
  factory :performance_book_export, class: 'Tasks::Models::PerformanceBookExport' do
    association :course
    association :role
  end
end
