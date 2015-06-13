FactoryGirl.define do
  factory :performance_report_export, class: 'Tasks::Models::PerformanceReportExport' do
    association :course
    association :role
  end
end
