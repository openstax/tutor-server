FactoryBot.define do
  factory :tasks_performance_report_export, class: '::Tasks::Models::PerformanceReportExport' do
    association :course, factory: :course_profile_course
    association :role, factory: :entity_role

    export { Tempfile.new([ 'export', '.xlsx' ]) }
  end
end
