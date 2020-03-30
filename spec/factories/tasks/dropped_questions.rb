FactoryBot.define do
  factory :tasks_dropped_question, class: '::Tasks::Models::DroppedQuestion' do
    association :task_plan, factory: :tasks_task_plan
    question_id { '1' }

    drop_method { [ :zeroed, :full_credit ].sample }
  end
end
