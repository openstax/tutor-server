require 'rails_helper'

RSpec.describe Tasks::Assistants::EventAssistant, type: :assistant do

  let(:num_taskees) { 3 }

  let(:course)      { FactoryGirl.create :course_profile_course }
  let(:period)      { FactoryGirl.create :course_membership_period, course: course }

  subject(:event_assistant) do
    FactoryGirl.create(:tasks_assistant, code_class_name: 'Tasks::Assistants::EventAssistant')
  end

  before do
    num_taskees.times do
      user = FactoryGirl.create(:user)
      AddUserAsPeriodStudent[user: user, period: period]
    end
  end

  it 'assigns tasked events to students' do
    task_plan = FactoryGirl.create(:tasks_task_plan,
                                   assistant: event_assistant,
                                   title: 'No class',
                                   description: 'No class today, kiddos',
                                   owner: course)

    tasks = DistributeTasks.call(task_plan).outputs.tasks

    expect(tasks.length).to eq num_taskees + 1
    expect(tasks.flat_map(&:task_type).uniq).to eq(['event'])
    expect(tasks.flat_map(&:title).uniq).to eq(['No class'])
    expect(tasks.flat_map(&:description).uniq).to eq(['No class today, kiddos'])
  end

end
