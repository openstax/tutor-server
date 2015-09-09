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
      user = FactoryGirl.create(:user_profile).entity_user
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

  it 'raises an error if taskees are not students' do
    task_plan = FactoryGirl.build(:tasks_task_plan,
                                  assistant: event_assistant,
                                  owner: course,
                                  num_tasking_plans: 0)

    # If the target of a tasking plan is an entity user,
    # taskee will be the user's default role,
    # which is not a student role
    FactoryGirl.create(:tasks_tasking_plan,
                       task_plan: task_plan,
                       target: UserProfile::Models::Profile.first)

    expect {
      DistributeTasks.call(task_plan)
    }.to raise_error(StandardError, 'Event assignment taskees must all be students')
  end
end
