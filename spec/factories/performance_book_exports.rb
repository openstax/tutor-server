FactoryGirl.define do
  factory :performance_book_export, class: 'Tasks::Models::PerformanceBookExport' do
    filename 'Physics_I_Performance'
    association :course
    association :role
  end
end
