require 'rails_helper'

RSpec.describe Tasks::Assistants::EventAssistant, type: :assistant do
  let(:course) { Entity::Course.create }
  let(:period) { CourseMembership::Models::Period.last }

  subject(:event_assistant) do
    FactoryGirl.create(:tasks_assistant,
                       code_class_name: 'Tasks::Assistants::EventAssistant')
  end

  before do
    CreatePeriod[course: course]

    3.times do
      profile = FactoryGirl.create(:user_profile)
      strategy = User::Strategies::Direct::User.new(profile)
      user = User::User.new(strategy: strategy)
      AddUserAsPeriodStudent[user: user, period: period]
    end
  end

  it 'assigns tasked events to students' do
    task_plan = FactoryGirl.build(:tasks_task_plan,
                                  assistant: event_assistant,
                                  title: 'No class',
                                  description: 'No class today, kiddos',
                                  owner: course)

    tasks = DistributeTasks.call(task_plan).outputs.entity_tasks.flat_map(&:task)

    expect(tasks.length).to eq 3
    expect(tasks.flat_map(&:task_type).uniq).to eq(['event'])
    expect(tasks.flat_map(&:title).uniq).to eq(['No class'])
    expect(tasks.flat_map(&:description).uniq).to eq(['No class today, kiddos'])
  end
end
