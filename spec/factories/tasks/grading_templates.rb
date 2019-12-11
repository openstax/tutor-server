FactoryBot.define do
  factory :tasks_grading_template, class: '::Tasks::Models::GradingTemplate' do
    association :course, factory: :course_profile_course

    task_plan_type                 { [ :reading, :homework ].sample }
    name                           { Faker::App.name }
    completion_weight              { rand.round(1) }
    correctness_weight             { (1 - completion_weight).round(1) }
    auto_grading_feedback_on       { [ :answer, :due, :publish ].sample }
    manual_grading_feedback_on     { [ :grade, :publish ].sample }
    late_work_penalty_applied      { [ :never, :immediately, :daily ].sample }
    late_work_penalty              { rand.round(1) }
    default_open_time              { '07:00:00' }
    default_due_time               { '21:00:00' }
    default_due_date_offset_days   { 7 }
    default_close_date_offset_days { 7 }
  end
end
