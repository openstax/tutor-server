FactoryBot.define do
  factory :tasks_task_step, class: '::Tasks::Models::TaskStep' do
    association :page, factory: :content_page
    tasked_type :tasks_tasked_reading

    transient do
      url nil
      content nil
      title nil
      skip_task false
    end

    after(:build) do |task_step, evaluator|
      tasked_options = { task_step: task_step, url: evaluator.url,
                         content: evaluator.content, title: evaluator.title }.compact
      task_step.tasked ||= FactoryBot.build(evaluator.tasked_type, tasked_options)

      task_options = { task_steps: [ task_step ] }
      task_step.task ||= FactoryBot.build(:tasks_task, task_options) unless evaluator.skip_task
    end
  end
end
