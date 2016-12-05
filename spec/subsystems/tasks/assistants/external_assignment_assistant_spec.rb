require 'rails_helper'

RSpec.describe Tasks::Assistants::ExternalAssignmentAssistant, type: :assistant do

  let(:url)             { 'https://www.example.org/external-assignment-one.pdf' }
  let(:templatized_url) { 'https://www.example.org/survey?id={{research_identifier}}' }
  let(:num_taskees)     { 3 }

  let(:assistant)      do
    FactoryGirl.create(
      :tasks_assistant, code_class_name: 'Tasks::Assistants::ExternalAssignmentAssistant'
    )
  end

  let(:course)         { FactoryGirl.create :course_profile_course }
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
    expect(tasks.length).to eq num_taskees + 1

    tasks.each do |task|
      expect(task.task_type).to eq 'external'
      expect(task.task_steps.length).to eq 1
      expect(task.task_steps.first.tasked.url).to eq url
    end
  end

  it 'assigns tasked external urls with templatized urls to students' do
    tasks = DistributeTasks.call(task_plan_2).outputs.tasks
    expect(tasks.length).to eq num_taskees + 1

    tasks.each do |task|
      expect(task.task_type).to eq 'external'
      expect(task.task_steps.length).to eq 1
    end

    # check that the research_identifier is in the tasked urls
    student_research_identifiers = students.map{ |student| student.role.research_identifier }
    teacher_student_research_identifier = period.teacher_student_role.research_identifier
    research_identifiers = (student_research_identifiers +
                            [teacher_student_research_identifier]).sort
    tasked_urls = tasks.map{ |task| task.task_steps.first.tasked.url }.sort

    tasked_urls.each_with_index do |tasked_url, i|
      expect(tasked_url).to end_with(research_identifiers[i])
    end
  end
end
