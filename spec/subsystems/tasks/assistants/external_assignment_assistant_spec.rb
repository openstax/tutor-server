require 'rails_helper'

RSpec.describe Tasks::Assistants::ExternalAssignmentAssistant, type: :assistant do
  let!(:assistant) {
    FactoryGirl.create(:tasks_assistant, code_class_name: 'Tasks::Assistants::ExternalAssignmentAssistant')
  }

  let!(:url) { 'https://www.example.org/external-assignment-one.pdf' }
  let!(:templatized_url) { 'https://www.example.org/survey?id={{deidentifier}}' }

  let!(:course) { Entity::Course.create }
  let!(:period) { CreatePeriod[course: course] }

  let!(:task_plan_1) {
    FactoryGirl.build(:tasks_task_plan,
                      assistant: assistant,
                      settings: { external_url: url },
                      owner: course,
                      num_tasking_plans: 0)
  }

  let!(:task_plan_2) {
    FactoryGirl.build(:tasks_task_plan,
                      assistant: assistant,
                      settings: { external_url: templatized_url },
                      owner: course,
                      num_tasking_plans: 0)
  }

  let!(:num_taskees) { 3 }

  let!(:students) {
    num_taskees.times.collect do
      user = FactoryGirl.create(:user_profile_profile).user
      AddUserAsPeriodStudent.call(user: user, period: period).outputs.student
    end
  }

  let!(:tasking_plans_1) {
    FactoryGirl.build(:tasks_tasking_plan,
                      task_plan: task_plan_1,
                      target: course)
  }

  let!(:tasking_plans_2) {
    FactoryGirl.create(:tasks_tasking_plan,
                       task_plan: task_plan_2,
                       target: course)
  }

  it 'assigns tasked external urls to students' do
    tasks = DistributeTasks.call(task_plan_1).outputs.entity_tasks.collect(&:task)
    expect(tasks.length).to eq num_taskees

    tasks.each do |task|
      expect(task.task_type).to eq 'external'
      expect(task.task_steps.length).to eq 1
      expect(task.task_steps.first.tasked.url).to eq url
    end
  end

  it 'assigns tasked external urls with templatized urls to students' do
    tasks = DistributeTasks.call(task_plan_2).outputs.entity_tasks.collect(&:task)
    expect(tasks.length).to eq num_taskees

    tasks.each do |task|
      expect(task.task_type).to eq 'external'
      expect(task.task_steps.length).to eq 1
    end

    # check that the deidentifier is in the tasked urls
    student_deidentifiers = students.collect { |s| s.deidentifier }
    student_deidentifiers.sort! { |a, b| a <=> b }
    tasked_urls = tasks.collect { |t| t.task_steps.first.tasked.url }
    tasked_urls.sort! { |a, b| a <=> b }

    tasked_urls.each_with_index do |tasked_url, i|
      expect(tasked_url).to end_with(student_deidentifiers[i])
    end
  end

  it 'raises an error if taskees are not students' do
    # If the target of a tasking plan is an entity user, taskee will be the
    # user's default role, which is not a student role
    FactoryGirl.create(:tasks_tasking_plan,
                       task_plan: task_plan_2,
                       target: students[0].role.user)

    expect {
      DistributeTasks.call(task_plan_2)
    }.to raise_error(StandardError).with_message(
      'External assignment taskees must all be students')
  end
end
