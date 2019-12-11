FactoryBot.define do
  factory :tasks_grading_template, class: '::Tasks::Models::GradingTemplate' do
    association :course, factory: :course_profile_course

    task_plan_type                 { [ :reading, :homework ].sample }
    name                           { Faker::App.name }
    completion_weight              { (rand * 10).round/10.0 }
    correctness_weight             { 1 - completion_weight }
    auto_grading_feedback_on       { [ :answer, :due, :auto_publish ].sample }
    manual_grading_feedback_on     { [ :grade, :manual_publish ].sample }
    late_work_immediate_penalty    { (rand * 10).round/10.0 }
    late_work_per_day_penalty      { (1 - late_work_immediate_penalty)*(rand * 10).round/10.0 }
    default_open_time              { '07:00:00' }
    default_due_time               { '21:00:00' }
    default_due_date_offset_days   { 7 }
    default_close_date_offset_days { 7 }
  end
end
