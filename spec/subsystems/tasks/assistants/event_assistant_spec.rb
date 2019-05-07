require 'rails_helper'

RSpec.describe Tasks::Assistants::EventAssistant, type: :assistant do
  let(:num_taskees)      { 3 }

  let(:course)           { FactoryBot.create :course_profile_course }
  let(:period)           { FactoryBot.create :course_membership_period, course: course }

  subject(:event_assistant) do
    FactoryBot.create(:tasks_assistant, code_class_name: 'Tasks::Assistants::EventAssistant')
  end

  before do
    num_taskees.times do
      user = FactoryBot.create(:user)
      AddUserAsPeriodStudent[user: user, period: period]
    end
  end

  context 'with no teacher_students' do
    it 'assigns tasked events to students' do
      task_plan = FactoryBot.create(:tasks_task_plan,
                                     assistant: event_assistant,
                                     title: 'No class',
                                     description: 'No class today, kiddos',
                                     owner: course)

      tasks = DistributeTasks.call(task_plan: task_plan).outputs.tasks

      expect(tasks.length).to eq num_taskees
      expect(tasks.flat_map(&:task_type).uniq).to eq(['event'])
      expect(tasks.flat_map(&:title).uniq).to eq(['No class'])
      expect(tasks.flat_map(&:description).uniq).to eq(['No class today, kiddos'])
    end
  end

  context 'with a teacher_student' do
    let!(:teacher_student) { FactoryBot.create :course_membership_teacher_student, period: period }

    it 'assigns tasked events to students and the teacher_student' do
      task_plan = FactoryBot.create(:tasks_task_plan,
                                     assistant: event_assistant,
                                     title: 'No class',
                                     description: 'No class today, kiddos',
                                     owner: course)

      tasks = DistributeTasks.call(task_plan: task_plan).outputs.tasks

      expect(tasks.length).to eq num_taskees + 1
      expect(tasks.flat_map(&:task_type).uniq).to eq(['event'])
      expect(tasks.flat_map(&:title).uniq).to eq(['No class'])
      expect(tasks.flat_map(&:description).uniq).to eq(['No class today, kiddos'])
    end
  end
end
