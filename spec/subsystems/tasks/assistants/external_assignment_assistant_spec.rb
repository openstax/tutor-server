require 'rails_helper'

RSpec.describe Tasks::Assistants::ExternalAssignmentAssistant, type: :assistant do
  let!(:assistant) {
    FactoryGirl.create(:tasks_assistant, code_class_name: 'Tasks::Assistants::ExternalAssignmentAssistant')
  }

  let!(:url) { 'https://www.example.org/external-assignment-one.pdf' }

  let!(:task_plan) {
    FactoryGirl.build(:tasks_task_plan,
                      assistant: assistant,
                      settings: { external_url: url },
                      num_tasking_plans: 0)
  }

  let!(:course) { task_plan.owner }
  let!(:period) { CreatePeriod[course: course] }

  let!(:num_taskees) { 3 }

  let!(:taskees) {
    num_taskees.times.collect do
      user = Entity::User.create
      AddUserAsPeriodStudent.call(user: user, period: period)
      user
    end
  }

  let!(:tasking_plans) {
    tps = taskees.collect do |taskee|
      task_plan.tasking_plans << FactoryGirl.build(:tasks_tasking_plan,
                                                   task_plan: task_plan,
                                                   target: taskee)
    end

    task_plan.save
    tps
  }

  it 'assigns tasked external urls to students' do
    tasks = DistributeTasks.call(task_plan).outputs.tasks
    expect(tasks.length).to eq num_taskees

    tasks.each do |task|
      expect(task.task_type).to eq 'external'
      expect(task.task_steps.length).to eq 1
      expect(task.task_steps.first.tasked.url).to eq url
    end
  end
end
