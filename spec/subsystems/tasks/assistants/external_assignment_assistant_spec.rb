require 'rails_helper'

RSpec.describe Tasks::Assistants::ExternalAssignmentAssistant, type: :assistant do

  let(:url)             { 'https://www.example.org/external-assignment-one.pdf' }
  let(:templatized_url) { 'https://www.example.org/survey?id={{deidentifier}}' }
  let(:num_taskees)     { 3 }

  let(:assistant)      do
    FactoryGirl.create(
      :tasks_assistant, code_class_name: 'Tasks::Assistants::ExternalAssignmentAssistant'
    )
  end

  let(:course)         { FactoryGirl.create :entity_course }
  let(:period)         { FactoryGirl.create :course_membership_period, course: course }

  let(:task_plan_1)    do
    FactoryGirl.create(:tasks_task_plan,
                       assistant: assistant,
                       settings: { external_url: url },
                       owner: course)
  end

  let(:task_plan_2)    do
    FactoryGirl.create(:tasks_task_plan,
                       assistant: assistant,
                       settings: { external_url: templatized_url },
                       owner: course)
  end

  let!(:students)       do
    num_taskees.times.map do
      user = FactoryGirl.create(:user)
      AddUserAsPeriodStudent.call(user: user, period: period).outputs.student
    end
  end

  it 'assigns tasked external urls to students' do
    tasks = DistributeTasks.call(task_plan_1).outputs.tasks
    expect(tasks.length).to eq num_taskees

    tasks.each do |task|
      expect(task.task_type).to eq 'external'
      expect(task.task_steps.length).to eq 1
      expect(task.task_steps.first.tasked.url).to eq url
    end
  end

  it 'assigns tasked external urls with templatized urls to students' do
    tasks = DistributeTasks.call(task_plan_2).outputs.tasks
    expect(tasks.length).to eq num_taskees

    tasks.each do |task|
      expect(task.task_type).to eq 'external'
      expect(task.task_steps.length).to eq 1
    end

    # check that the deidentifier is in the tasked urls
    student_deidentifiers = students.map(&:deidentifier)
    student_deidentifiers.sort! { |a, b| a <=> b }
    tasked_urls = tasks.map { |t| t.task_steps.first.tasked.url }
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
                       target: students[0].role.profile)

    expect {
      DistributeTasks.call(task_plan_2)
    }.to raise_error(StandardError).with_message(
      /External assignment taskees must all be students/)
  end
end
