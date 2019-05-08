require 'rails_helper'

RSpec.describe Tasks::Assistants::ExternalAssignmentAssistant, type: :assistant do

  let(:url)             { 'https://www.example.org/external-assignment-one.pdf' }
  let(:templatized_url) { 'https://www.example.org/survey?id={{research_identifier}}' }
  let(:num_taskees)     { 3 }

  let(:assistant)      do
    FactoryBot.create(
      :tasks_assistant, code_class_name: 'Tasks::Assistants::ExternalAssignmentAssistant'
    )
  end

  let(:course)         { FactoryBot.create :course_profile_course }
  let(:period)         { FactoryBot.create :course_membership_period, course: course }

  let(:task_plan_1)    do
    FactoryBot.create(:tasks_task_plan,
                       assistant: assistant,
                       settings: { external_url: url },
                       owner: course)
  end

  let(:task_plan_2)    do
    FactoryBot.create(:tasks_task_plan,
                       assistant: assistant,
                       settings: { external_url: templatized_url },
                       owner: course)
  end

  let!(:students)       do
    num_taskees.times.map do
      user = FactoryBot.create(:user)
      AddUserAsPeriodStudent.call(user: user, period: period).outputs.student
    end
  end

  context "with no teacher_students" do
    it 'assigns tasked external urls to students' do
      tasks = DistributeTasks.call(task_plan: task_plan_1).outputs.tasks
      expect(tasks.length).to eq num_taskees

      tasks.each do |task|
        expect(task.task_type).to eq 'external'
        expect(task.task_steps.length).to eq 1
        expect(task.task_steps.first.tasked.url).to eq url
      end
    end

    it 'assigns tasked external urls with templatized urls to students' do
      tasks = DistributeTasks.call(task_plan: task_plan_2).outputs.tasks
      expect(tasks.length).to eq num_taskees

      tasks.each do |task|
        expect(task.task_type).to eq 'external'
        expect(task.task_steps.length).to eq 1
      end

      # check that the research_identifier is in the tasked urls
      student_research_identifiers = students.map { |student| student.role.research_identifier }
      research_identifiers = student_research_identifiers.sort
      tasked_urls = tasks.map { |task| task.task_steps.first.tasked.url }.sort

      tasked_urls.each_with_index do |tasked_url, i|
        expect(tasked_url).to end_with(research_identifiers[i])
      end
    end
  end

  context "with a teacher_student" do
    let!(:teacher_student_role) do
      FactoryBot.create(:course_membership_teacher_student, period: period).role
    end

    it 'assigns tasked external urls to students and the teacher_student' do
      tasks = DistributeTasks.call(task_plan: task_plan_1).outputs.tasks
      expect(tasks.length).to eq num_taskees + 1

      tasks.each do |task|
        expect(task.task_type).to eq 'external'
        expect(task.task_steps.length).to eq 1
        expect(task.task_steps.first.tasked.url).to eq url
      end
    end

    it 'assigns tasked external urls with templatized urls to students and the teacher_student' do
      tasks = DistributeTasks.call(task_plan: task_plan_2).outputs.tasks
      expect(tasks.length).to eq num_taskees + 1

      tasks.each do |task|
        expect(task.task_type).to eq 'external'
        expect(task.task_steps.length).to eq 1
      end

      # check that the research_identifier is in the tasked urls
      student_research_identifiers = students.map { |student| student.role.research_identifier }
      teacher_student_research_identifier = teacher_student_role.research_identifier
      research_identifiers = (student_research_identifiers +
                              [teacher_student_research_identifier]).sort
      tasked_urls = tasks.map{ |task| task.task_steps.first.tasked.url }.sort

      tasked_urls.each_with_index do |tasked_url, i|
        expect(tasked_url).to end_with(research_identifiers[i])
      end
    end
  end
end
